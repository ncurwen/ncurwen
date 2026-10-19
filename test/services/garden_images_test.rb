require "test_helper"

class GardenImagesTest < ActiveSupport::TestCase
  test "parses filename dates and returns newest-first" do
    base = Rails.root.join("app/assets/images").to_s
    paths = [
      "#{base}/garden/2024/IMG_20240715_120000.jpg",
      "#{base}/garden/2026/IMG_20260101_093000.JPEG",
      "#{base}/garden/2021/cover.jpg" # no timestamp in name
    ]

    images = Dir.stub(:glob, paths) { GardenImages.new.call }

    assert_equal %w[2026 2024 2021], images.map { |i| i[:year] }, "sorted newest-first"

    dated = images.first
    assert_equal "garden/2026/IMG_20260101_093000.JPEG", dated[:path]
    assert_equal "IMG_20260101_093000", dated[:basename]
    assert_equal "2026-01-01 09:30", dated[:date]
    assert_equal "202601010930", dated[:sort_key]

    dateless = images.last
    assert_nil dateless[:date], "no date when the filename lacks a timestamp"
    assert_equal "2021", dateless[:year], "year falls back to the directory"
    assert_equal "202100000000", dateless[:sort_key]
  end

  test "points each photo at its derivatives, or nil when they aren't built yet" do
    base = Rails.root.join("app/assets/images").to_s
    paths = [ "#{base}/garden/2024/IMG_20240715_120000.jpg" ]

    # A fresh checkout has no derivatives — they're generated at build time and
    # gitignored — so every one comes back nil and the gallery uses the original.
    missing = Dir.stub(:glob, paths) { GardenImages.new.call }.sole
    assert_nil missing[:thumb_240_webp]
    assert_nil missing[:thumb_480_webp]
    assert_nil missing[:thumb_480_jpg]
    assert_nil missing[:large_webp]

    # Once generated, each is a logical path mirroring the source's year folder.
    built = File.stub(:exist?, true) do
      Dir.stub(:glob, paths) { GardenImages.new.call }
    end.sole

    assert_equal "garden-derivatives/2024/IMG_20240715_120000.240.webp", built[:thumb_240_webp]
    assert_equal "garden-derivatives/2024/IMG_20240715_120000.480.webp", built[:thumb_480_webp]
    assert_equal "garden-derivatives/2024/IMG_20240715_120000.480.jpg", built[:thumb_480_jpg]
    assert_equal "garden-derivatives/2024/IMG_20240715_120000.large.webp", built[:large_webp]
  end

  test "reads dimensions from the build-time manifest" do
    base = Rails.root.join("app/assets/images").to_s
    paths = [ "#{base}/garden/2024/IMG_20240715_120000.jpg" ]
    manifest = { "garden/2024/IMG_20240715_120000.jpg" => { "width" => 1707, "height" => 1280 } }

    image = GardenDerivatives.stub(:manifest, manifest) do
      Dir.stub(:glob, paths) { GardenImages.new.call }
    end.sole
    assert_equal 1707, image[:width]
    assert_equal 1280, image[:height]

    # Unlisted photos simply have unknown dimensions; nothing raises.
    unlisted = GardenDerivatives.stub(:manifest, {}) do
      Dir.stub(:glob, paths) { GardenImages.new.call }
    end.sole
    assert_nil unlisted[:width]
    assert_nil unlisted[:height]
  end
end
