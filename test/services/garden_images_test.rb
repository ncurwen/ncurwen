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
end
