# Scans app/assets/images/garden for photos and returns them newest-first,
# parsing the date and year out of each filename for the gallery timeline.
#
# Each photo also carries the logical paths of its generated derivatives (see
# GardenDerivatives) and its dimensions, read from the build-time manifest.
# Derivatives are *not* committed, so any of them may be absent on a fresh
# checkout — every one is existence-checked and comes back nil when missing,
# which lets the gallery fall back to the original rather than 500.
#
# Paths stay logical (never URLs): resolving them through Propshaft is the
# component's job, and asset_path raises on anything it cannot resolve.
#
# Recomputes on every call in development so newly added images show up without
# a restart; memoises everywhere else.
class GardenImages < ApplicationService
  GLOB = "app/assets/images/garden/**/*.{jpg,jpeg,JPG,JPEG,png,PNG}".freeze

  ASSET_ROOT = "app/assets/images".freeze

  # "garden-derivatives" — derived from the generator so the two can't drift.
  DERIVATIVES_DIR = GardenDerivatives::OUTPUT_DIR.delete_prefix("#{ASSET_ROOT}/").freeze

  # Hash key => the filename suffix GardenDerivatives writes.
  DERIVATIVES = {
    thumb_240_webp: "240.webp",
    thumb_480_webp: "480.webp",
    thumb_480_jpg: "480.jpg",
    large_webp: "large.webp"
  }.freeze

  def self.call
    return super if Rails.env.development?

    @images ||= super
  end

  def call
    Dir.glob(Rails.root.join(GLOB))
      .map do |path|
        basename = File.basename(path)
        rel_path = path.sub(base, "")
        m = basename.match(/(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})/)
        date = m && "#{m[1]}-#{m[2]}-#{m[3]} #{m[4]}:#{m[5]}"
        year = (m && m[1]) || rel_path[%r{garden/(\d{4})/}, 1]
        sort_key = m ? "#{m[1]}#{m[2]}#{m[3]}#{m[4]}#{m[5]}" : "#{year}00000000"
        { path: rel_path, date: date, basename: File.basename(basename, ".*"), year: year, sort_key: sort_key }
          .merge(derivatives_for(rel_path))
          .merge(dimensions_for(rel_path))
      end
      .sort_by { |img| img[:sort_key] }
      .reverse
  end

  private

  def base
    @base ||= Rails.root.join("#{ASSET_ROOT}/").to_s
  end

  # garden/2026/IMG_x.JPEG -> garden-derivatives/2026/IMG_x.<suffix>, or nil
  # when that file hasn't been generated.
  def derivatives_for(rel_path)
    dir = File.dirname(rel_path).sub(%r{\Agarden(/|\z)}, "#{DERIVATIVES_DIR}\\1")
    stem = File.basename(rel_path, ".*")

    DERIVATIVES.transform_values do |suffix|
      logical = File.join(dir, "#{stem}.#{suffix}")
      logical if File.exist?(Rails.root.join(ASSET_ROOT, logical))
    end
  end

  def dimensions_for(rel_path)
    manifest.fetch(rel_path, {}).then { |d| { width: d["width"], height: d["height"] } }
  end

  # Written by GardenDerivatives alongside the derivatives; empty until the
  # generator has run, in which case dimensions are simply unknown.
  def manifest
    @manifest ||= GardenDerivatives.manifest(root: Rails.root.to_s)
  end
end
