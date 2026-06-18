require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "the persistent nav moves between pages via Turbo" do
    visit root_path
    assert_selector "header#primary-nav"

    click_link "experience"
    assert_title(/Experience/)

    click_link "garden"
    assert_title(/Garden/)

    click_link "contact"
    assert_title(/Contact/)

    # The morph/permanent nav should still be present after navigating.
    assert_selector "header#primary-nav"
  end
end
