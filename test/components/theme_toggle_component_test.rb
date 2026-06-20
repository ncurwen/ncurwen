require "test_helper"
require "view_component/test_helpers"

class ThemeToggleComponentTest < ViewComponent::TestCase
  test "defaults to checked (dark) when no light_mode cookie is set" do
    render_inline(ThemeToggleComponent.new)

    assert_selector "input[type='checkbox'][checked]"
  end

  test "is unchecked (light) when the light_mode cookie is true" do
    vc_test_request.cookie_jar[:light_mode] = "true"

    render_inline(ThemeToggleComponent.new)

    assert_selector "input[type='checkbox']"
    assert_no_selector "input[checked]"
  end

  test "renders both swap icons and the toggle tooltip" do
    render_inline(ThemeToggleComponent.new)

    assert_selector ".tooltip[data-tip='Toggle theme']"
    assert_selector "svg.swap-off"
    assert_selector "svg.swap-on"
  end
end
