require "test_helper"

# Covers the decisions the generator makes — which photos need rebuilding, where
# each derivative lands, and what the manifest says — without invoking libvips,
# so CI needs no image tooling.
class GardenDerivativesTest < ActiveSupport::TestCase
  def setup
    @root = Dir.mktmpdir
    @source = File.join(@root, GardenDerivatives::SOURCE_DIR, "2024", "IMG_20240715_120000.HEIC_compressed.JPEG")
    FileUtils.mkdir_p(File.dirname(@source))
    File.write(@source, "not really a jpeg")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  test "mirrors the source's year folder and suffixes each variant" do
    assert_equal %w[240.webp 480.webp 480.jpg large.webp], GardenDerivatives::VARIANTS.keys

    GardenDerivatives::VARIANTS.each_key do |suffix|
      assert_equal File.join(@root, "app/assets/images/garden-derivatives/2024",
                             "IMG_20240715_120000.HEIC_compressed.#{suffix}"),
                   destination(suffix)
    end
  end

  # Each assertion gets a fresh generator, as every real run does — an instance
  # settles its answers once and is not meant to outlive the run.
  test "rebuilds only what is missing or older than its source" do
    assert stale?, "nothing generated yet"

    touch_all(File.mtime(@source) + 1)
    refute stale?, "every derivative newer than the source"

    # A re-exported photo must win over the derivatives built from the old one.
    FileUtils.touch(@source, mtime: Time.now + 60)
    assert stale?, "source newer than its derivatives"

    touch_all(File.mtime(@source) + 1)
    FileUtils.rm(destination("480.jpg"))
    assert stale?, "one variant missing is enough"
  end

  test "force rebuilds even when everything is up to date" do
    touch_all(File.mtime(@source) + 1)

    refute stale?
    assert stale?(force: true)
  end

  test "rebuilds everything when the encoder settings have changed" do
    touch_all(File.mtime(@source) + 1)
    refute stale?

    # Same sources, different output: only the recorded stamp can catch this.
    write_manifest("stamp-from-different-settings")
    assert stale?
  end

  test "stamps the encoder settings so a quality change invalidates the tree" do
    # The stamp is derived, not hand-bumped: editing a size, quality or format
    # has to be enough on its own to force a rebuild.
    original = GardenDerivatives::VARIANTS
    tweaked = original.merge("large.webp" => original["large.webp"].merge(quality: 99))

    assert_equal GardenDerivatives::MANIFEST_VERSION, stamp_for(original)
    refute_equal GardenDerivatives::MANIFEST_VERSION, stamp_for(tweaked)
  end

  test "reads back an empty manifest when nothing has been generated" do
    assert_empty GardenDerivatives.manifest(root: @root)

    path = File.join(@root, GardenDerivatives::OUTPUT_DIR, GardenDerivatives::MANIFEST_NAME)
    FileUtils.mkdir_p(File.dirname(path))

    File.write(path, "{ truncated")
    assert_empty GardenDerivatives.manifest(root: @root), "a half-written manifest must not raise"

    File.write(path, { "version" => 1, "images" => { "garden/a.JPEG" => { "width" => 4, "height" => 3 } } }.to_json)
    assert_equal({ "width" => 4, "height" => 3 }, GardenDerivatives.manifest(root: @root).fetch("garden/a.JPEG"))
  end

  private

  def destination(suffix)
    GardenDerivatives.new(root: @root).send(:destination, @source, suffix)
  end

  def stale?(force: false)
    GardenDerivatives.new(root: @root, force: force).send(:stale?, @source)
  end

  def stamp_for(variants)
    Digest::SHA256.hexdigest(variants.inspect)[0, 12]
  end

  def write_manifest(version)
    path = File.join(@root, GardenDerivatives::OUTPUT_DIR, GardenDerivatives::MANIFEST_NAME)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, { "version" => version, "images" => {} }.to_json)
  end

  def touch_all(mtime)
    write_manifest(GardenDerivatives::MANIFEST_VERSION)
    GardenDerivatives::VARIANTS.each_key do |suffix|
      path = destination(suffix)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path, mtime: mtime)
    end
  end
end
