class PhotoGalleryComponent < ViewComponent::Base
  # The one expressive system on this page: a growing year read through its
  # seasons. Each timestamp gets a season dot; each year a season-gradient rule.
  SEASON_COLOR = {
    spring: "oklch(72% 0.15 145)", # fresh sprout green
    summer: "oklch(80% 0.15 85)",  # high-summer gold
    autumn: "oklch(68% 0.15 55)",  # late amber
    winter: "oklch(72% 0.07 230)"  # cool dormancy
  }.freeze

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
        season: season_color(month)
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

  def season_color(month)
    SEASON_COLOR[season(month)]
  end

  def month_range(imgs)
    months = imgs.map { |i| i[:month] }.compact
    return nil if months.empty?

    lo, hi = months.min, months.max
    lo == hi ? MONTHS[lo] : "#{MONTHS[lo]}–#{MONTHS[hi]}"
  end

  # A hairline that travels from the year's first season to its last.
  def season_gradient(imgs)
    months = imgs.map { |i| i[:month] }.compact
    return SEASON_COLOR[:spring] if months.empty?

    "linear-gradient(to right, #{season_color(months.min)}, #{season_color(months.max)})"
  end
end
