class PhotoGalleryComponent < ApplicationComponent
  # The one expressive system on this page: a growing year read through its
  # seasons. Each timestamp gets a season dot; each year a season-gradient rule.
  # The component speaks in season *keys* (e.g. "spring"); the colours live in
  # CSS (--season-* plus .season-dot/.season-bar in application.tailwind.css), so
  # the view paints via classes/data-attributes — never inline styles, which CSP
  # forbids and a nonce can't authorise.
  MONTHS = %w[· Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

  # What a tile actually occupies, so the browser can pick 240w on a DPR-1
  # screen instead of always pulling 480w. Derived from the real geometry:
  # the page is max-w-5xl (1024px) with px-4, the grid has gap-3 (12px), and
  # Tailwind's sm:/md: breakpoints are 640/768. Getting this wrong silently
  # wastes the 240w variant.
  TILE_SIZES = "(min-width: 1024px) 239px, " \
               "(min-width: 768px) calc((100vw - 68px) / 4), " \
               "(min-width: 640px) calc((100vw - 56px) / 3), " \
               "calc((100vw - 44px) / 2)".freeze

  LOG_ICON = "🌱".freeze

  def initialize(images:, notes: [])
    @images = images
    @notes = notes || []
  end

  def render?
    @images.any?
  end

  private

  attr_reader :images, :notes

  # Garden notes for a single year chapter (string year), oldest first.
  def notes_for(year)
    notes_by_year.fetch(year, [])
  end

  def notes_by_year
    @notes_by_year ||= notes.select { |n| n[:date] }
                            .group_by { |n| n[:date].year.to_s }
                            .transform_values { |ns| ns.sort_by { |n| n[:date] } }
  end

  # Display-ordered (newest first) with everything the view and the Stimulus
  # controller need, computed once. The array position is the stable lightbox
  # index shared with the JSON in `gallery_data`.
  def entries
    @entries ||= images.each_with_index.map do |img, i|
      # :date is a "YYYY-MM-DD…" string, so chars 5–6 are the month (nil when absent).
      month = img[:date]&.slice(5, 2)&.to_i
      img.merge(
        idx: i,
        month: month,
        season: season(month),
        original: asset_path(img[:path]),
        # Every derivative falls back to the original: they are generated at
        # build time and absent on a fresh checkout, and asset_path raises
        # rather than returning nil for anything it can't resolve.
        tile_src: asset_path(img[:thumb_480_jpg] || img[:path]),
        tile_srcset: tile_srcset(img),
        large: asset_path(img[:large_webp] || img[:path])
      )
    end
  end

  # The WebP <source> for a tile, or nil when either width is missing — in
  # which case the template emits no <source> at all and the <img> stands alone.
  def tile_srcset(img)
    return nil unless img[:thumb_240_webp] && img[:thumb_480_webp]

    srcset([ [ img[:thumb_240_webp], "240w" ], [ img[:thumb_480_webp], "480w" ] ])
  end

  # Rails has no helper for this: image_tag digests a srcset: option, but a
  # bare <source> doesn't go through it and picture_tag only emits
  # single-URL sources with no width descriptors. Takes ordered pairs rather
  # than a hash so two candidates resolving to the same file still both appear.
  def srcset(pairs)
    pairs.map { |path, descriptor| "#{asset_path(path)} #{descriptor}" }.join(", ")
  end

  def latest
    entries.first
  end

  # Year chapters, newest first.
  def chapters
    entries.group_by { |img| img[:year] }
           .sort_by { |year, _| -year.to_i }
  end

  # Frames grouped by month number (1–12), for presence and chip counts.
  def entries_by_month
    @entries_by_month ||= entries.select { |e| e[:month] }.group_by { |e| e[:month] }
  end

  # Months that actually have photos, in calendar order (Jan→Dec).
  def months_present
    entries_by_month.keys.sort
  end

  # Tooltip for a month chip: every year that has a photo in this month, across
  # the whole (unfiltered) dataset, newest first.
  def years_for_month(m)
    "Years: " + entries_by_month[m].map { |e| e[:year] }.compact.uniq.sort.reverse.join(", ")
  end

  # Tooltip for a year chip: every month present in that year, in calendar order,
  # by name. (Distinct from month_range, which collapses to a Jan–Jul span.)
  def months_label(imgs)
    "Months: " + imgs.map { |e| e[:month] }.compact.uniq.sort.map { |n| MONTHS[n] }.join(", ")
  end

  # Section list for the reusable TableOfContentsComponent, newest year first.
  # Ids match the `garden-<year>` anchors on the chapter containers.
  def year_sections
    [ { id: "garden-filters", label: "filters" } ] +
      chapters.map { |year, _imgs| { id: "garden-#{year}", label: year } }
  end

  # The subset the Stimulus controller reads, by array position.
  def gallery_data
    entries.map { |e| e.slice(:large, :original, :date, :basename, :year, :season, :month, :width, :height) }
  end

  def span_label
    years = images.map { |i| i[:year] }.compact.uniq
    years.length > 1 ? "#{years.min}–#{years.max}" : years.first
  end

  # A filter chip's photo count, shown as a small image glyph + the number, so
  # the figure reads as "N frames" (the page's unit) instead of a bare digit
  # mashed against the year/month label. The number lives alone in the
  # [data-chip-count] span so the Stimulus controller can rewrite it on every
  # re-count; the glyph and the sr-only "frames" are siblings it leaves intact.
  def frame_count(n)
    tag.span(class: "inline-flex items-center gap-1 opacity-60") do
      safe_join([
        lucide_icon("image", class: "w-3 h-3"),
        tag.span(n, data: { chip_count: true }),
        tag.span(" frames", class: "sr-only")
      ])
    end
  end

  def season(month)
    case month
    when 3..5  then :spring
    when 6..8  then :summer
    when 9..11 then :autumn
    else            :winter
    end
  end

  def month_range(imgs)
    months = imgs.map { |i| i[:month] }.compact
    return nil if months.empty?

    lo, hi = months.min, months.max
    lo == hi ? MONTHS[lo] : "#{MONTHS[lo]}–#{MONTHS[hi]}"
  end

  # Endpoint season keys for a year's hairline (.season-bar), travelling from the
  # first season pictured to the last. Empty falls back to spring/spring.
  def season_range(imgs)
    months = imgs.map { |i| i[:month] }.compact
    return [ :spring, :spring ] if months.empty?

    [ season(months.min), season(months.max) ]
  end
end
