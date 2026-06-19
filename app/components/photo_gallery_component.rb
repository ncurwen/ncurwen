class PhotoGalleryComponent < ViewComponent::Base
  # The one expressive system on this page: a growing year read through its
  # seasons. Each timestamp gets a season dot; each year a season-gradient rule.
  # The component speaks in season *keys* (e.g. "spring"); the colours live in
  # CSS (--season-* plus .season-dot/.season-bar in application.tailwind.css), so
  # the view paints via classes/data-attributes — never inline styles, which CSP
  # forbids and a nonce can't authorise.
  MONTHS = %w[· Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

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
      month = img[:date]&.slice(5, 2)&.to_i
      img.merge(
        idx: i,
        url: helpers.asset_path(img[:path]),
        month: month,
        season: season(month)
      )
    end
  end

  def latest
    entries.first
  end

  # Year chapters, newest first.
  def chapters
    entries.group_by { |img| img[:year] }
           .sort_by { |year, _| -year.to_i }
  end

  # Section list for the reusable TableOfContentsComponent, newest year first.
  # Ids match the `garden-<year>` anchors on the chapter containers.
  def year_sections
    [ { id: "garden-filters", label: "filter" } ] +
      chapters.map { |year, _imgs| { id: "garden-#{year}", label: year } }
  end

  # The subset the Stimulus controller reads, by array position.
  def gallery_data
    entries.map { |e| e.slice(:url, :date, :basename, :year, :season) }
  end

  def span_label
    years = images.map { |i| i[:year] }.compact.uniq
    years.length > 1 ? "#{years.min}–#{years.max}" : years.first
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
