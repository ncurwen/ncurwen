require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "years_experience counts whole years since the career start" do
    # Career start is 2014-01-01.
    assert_equal 10, years_experience(as_of: Date.new(2024, 7, 1))
  end

  test "years_experience floors partial years rather than rounding up" do
    # Most of the way through the 11th year still reads as 10.
    assert_equal 10, years_experience(as_of: Date.new(2024, 12, 31))
  end
end
