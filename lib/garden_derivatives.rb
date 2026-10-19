require "digest"
require "fileutils"
require "json"

# Builds the resized, modern-format copies of the garden photos that /garden
# actually serves. The originals are ~1.1 MB each and get painted into ~239x160
# tiles, so shipping them unchanged costs ~103 MB for a full scroll of the page.
#
# Output is *generated, never committed* — the Dockerfile runs this on its own
# layer before `assets:precompile`, so Propshaft fingerprints the derivatives
# like any other asset. Run it by hand in development with `bin/rails
# garden:derivatives`.
#
# Deliberately plain Ruby with no Rails dependency: the Docker build runs it
# before the app code is copied in, so there is no framework to boot. Rails
# still autoloads it from lib/ for the rake task.
class GardenDerivatives
  SOURCE_DIR = "app/assets/images/garden".freeze
  OUTPUT_DIR = "app/assets/images/garden-derivatives".freeze

  # Propshaft's load path rejects dotfiles (LoadPath#without_dotfiles), so this
  # can live inside app/assets/images without ever being served or precompiled.
  # It carries each source's dimensions, which the gallery needs for width/height
  # and cannot otherwise know — the corpus is a mix of portrait and landscape at
  # several sizes. Named .dimensions rather than .manifest to keep it clearly
  # distinct from Propshaft's own public/assets/.manifest.json.
  MANIFEST_NAME = ".dimensions.json".freeze

  SOURCE_GLOB = "**/*.{jpg,jpeg,JPG,JPEG,png,PNG}".freeze

  # Tiles render at ~239px wide (4 columns inside a max-w-5xl), so 480w covers
  # DPR 2 and 240w covers DPR 1; at that size q72 is indistinguishable from the
  # source and the bytes matter, since a full scroll loads all 94.
  #
  # `large` feeds the hero and the lightbox, which fills the screen — a very
  # different job. It keeps the source's own resolution (these photos are only
  # 1.3–1.7 MP, and a retina lightbox already wants more pixels than they have,
  # so there is nothing to spare) and takes a much higher quality. One is
  # fetched at a time, so it can afford to.
  #
  # q92 sits at ~42.5 dB PSNR against the source, against 40.5 at q88 and 44.3
  # at q95 — past here the curve flattens while the bytes keep climbing. Note
  # the ceiling is the sources themselves: the hero paints a 1280px-wide photo
  # across a 1984 device-px banner, and no encoder setting invents those pixels.
  VARIANTS = {
    "240.webp" => { width: 240, format: :webp, quality: 72 },
    "480.webp" => { width: 480, format: :webp, quality: 72 },
    "480.jpg" => { width: 480, format: :jpeg, quality: 72 },
    "large.webp" => { native: true, format: :webp, quality: 92 }
  }.freeze

  # Changing a size, quality or format alters every output without touching a
  # single source, so mtime can't see it. Rather than a hand-bumped integer —
  # which is one forgotten edit away from silently shipping stale derivatives —
  # stamp the settings themselves, so any change invalidates the whole tree.
  MANIFEST_VERSION = Digest::SHA256.hexdigest(VARIANTS.inspect)[0, 12].freeze

  # Stand-in for "no height constraint" when bounding a thumbnail by width only.
  NO_LIMIT = 100_000

  def self.call(...) = new(...).call

  # The dimensions sidecar, as written by the last run — source logical path =>
  # {"width" =>, "height" =>}. Empty until the generator has run, so callers get
  # "unknown" rather than an error on a checkout with no derivatives.
  def self.manifest(root: Dir.pwd)
    read_manifest(root).fetch("images", {})
  end

  def self.read_manifest(root)
    path = File.join(root, OUTPUT_DIR, MANIFEST_NAME)
    return {} unless File.exist?(path)

    JSON.parse(File.read(path))
  rescue JSON::ParserError
    {}
  end

  def initialize(root: Dir.pwd, force: false, out: $stdout)
    @root = File.expand_path(root)
    @force = force
    @out = out
  end

  def call
    require_vips

    written = skipped = 0
    manifest = {}

    sources.each do |source|
      manifest[logical_path(source)] = dimensions(source)

      if stale?(source)
        generate(source)
        written += 1
      else
        skipped += 1
      end
    end

    write_manifest(manifest)
    @out.puts "garden derivatives: #{written} written, #{skipped} up to date (#{sources.size} photos)"
    self
  end

  private

  attr_reader :root, :force

  def sources
    @sources ||= Dir.glob(File.join(root, SOURCE_DIR, SOURCE_GLOB)).sort
  end

  # Path relative to the asset load path root, matching what GardenImages
  # returns as :path — e.g. "garden/2026/IMG_x.HEIC_compressed.JPEG".
  def logical_path(source)
    source.delete_prefix(File.join(root, "app/assets/images") + "/")
  end

  # Mirrors the source's year subdirectory: garden/2026/IMG_x.JPEG becomes
  # garden-derivatives/2026/IMG_x.<suffix>.
  def destination(source, suffix)
    relative = source.delete_prefix(File.join(root, SOURCE_DIR) + "/")
    dir = File.dirname(relative)
    base = File.basename(relative, ".*")
    File.join(root, OUTPUT_DIR, dir, "#{base}.#{suffix}")
  end

  # Rebuild when anything is missing or older than the source. Plain mtime is
  # safe here precisely because derivatives are not committed — the
  # git-checkout-timestamp hazard only applies to tracked generated files.
  def stale?(source)
    return true if force || settings_changed?

    mtime = File.mtime(source)
    VARIANTS.each_key.any? do |suffix|
      path = destination(source, suffix)
      !File.exist?(path) || File.mtime(path) < mtime
    end
  end

  # A quality or variant change alters every output without touching a single
  # source, so mtime can't see it — the recorded version is what catches it.
  def settings_changed?
    @settings_changed = self.class.read_manifest(root)["version"] != MANIFEST_VERSION if @settings_changed.nil?
    @settings_changed
  end

  def generate(source)
    VARIANTS.each do |suffix, spec|
      path = destination(source, suffix)
      FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, encode(thumbnail(source, spec), spec))
    end
  end

  # The file-based Vips::Image.thumbnail shrinks on load (JPEG DCT scaling) and
  # honours EXIF orientation by default, so it is several times cheaper than
  # loading then resizing. `size: :down` never upscales. copy_memory materialises
  # the result so the same decode can feed more than one save — without it the
  # second save fails with an out-of-order read on the sequential JPEG.
  def thumbnail(source, spec)
    # `native` bounds nothing: with size: :down the image comes through at its
    # own resolution, still autorotated and colour-managed like the rest.
    width = spec[:native] ? NO_LIMIT : (spec[:long_edge] || spec[:width])
    height = spec[:native] || spec[:width] ? NO_LIMIT : spec[:long_edge]
    Vips::Image.thumbnail(source, width, height: height, size: :down, **colour_options).copy_memory
  end

  def encode(image, spec)
    q = spec.fetch(:quality)
    case spec[:format]
    when :webp then image.webpsave_buffer(Q: q, effort: 6, **icc_options)
    when :jpeg then image.jpegsave_buffer(Q: q, optimize_coding: true, subsample_mode: :on, **icc_options)
    end
  end

  # 88 of the 94 photos are tagged Display P3. Dropping the profile would make
  # browsers read those values as sRGB and the greens go flat — and worse,
  # inconsistently, since the untouched original is still served as the
  # non-WebP fallback. Keeping it costs ~536 bytes per file.
  #
  # `keep:` needs libvips >= 8.15. On older builds, convert to sRGB instead:
  # a slightly narrower gamut, but the colour stays right.
  def keep_icc? = Vips.at_least_libvips?(8, 15)

  def icc_options = keep_icc? ? { keep: [ :icc ] } : { strip: true }

  # On the fallback path the profile is dropped, so the pixels must be
  # *converted* into sRGB first. Stripping a Display P3 tag without converting
  # is exactly the failure this guards against.
  def colour_options = keep_icc? ? {} : { export_profile: "srgb" }

  def dimensions(source)
    image = Vips::Image.new_from_file(source, access: :sequential).autorot
    { "width" => image.width, "height" => image.height }
  end

  def write_manifest(images)
    path = File.join(root, OUTPUT_DIR, MANIFEST_NAME)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate({ "version" => MANIFEST_VERSION, "images" => images }))
  end

  def require_vips
    require "vips"
  rescue LoadError
    abort "garden derivatives: libvips is missing. Install it with `brew install vips` " \
          "(it is already present in the Docker image). /garden still renders without " \
          "derivatives — it just serves the full-size originals."
  end
end
