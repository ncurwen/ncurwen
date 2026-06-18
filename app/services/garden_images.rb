# Scans app/assets/images/garden for photos and returns them newest-first,
# parsing the date and year out of each filename for the gallery timeline.
#
# Recomputes on every call in development so newly added images show up without
# a restart; memoises everywhere else.
class GardenImages < ApplicationService
  GLOB = "app/assets/images/garden/**/*.{jpg,jpeg,JPG,JPEG,png,PNG}".freeze

  def self.call
    return super if Rails.env.development?

    @images ||= super
  end

  def call
    base = Rails.root.join("app/assets/images/").to_s

    Dir.glob(Rails.root.join(GLOB))
      .map do |path|
        basename = File.basename(path)
        rel_path = path.sub(base, "")
        m = basename.match(/(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})/)
        date = m && "#{m[1]}-#{m[2]}-#{m[3]} #{m[4]}:#{m[5]}"
        year = (m && m[1]) || rel_path[%r{garden/(\d{4})/}, 1]
        sort_key = m ? "#{m[1]}#{m[2]}#{m[3]}#{m[4]}#{m[5]}" : "#{year}00000000"
        { path: rel_path, date: date, basename: File.basename(basename, ".*"), year: year, sort_key: sort_key }
      end
      .sort_by { |img| img[:sort_key] }
      .reverse
  end
end
