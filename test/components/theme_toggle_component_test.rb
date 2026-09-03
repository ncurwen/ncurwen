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

  # The invitation's cookie has a third state — absent, meaning "follow the
  # device" — which the server can't resolve, so it renders light and the
  # Stimulus controller corrects the icon on connect.
  def wedding_toggle
    ThemeToggleComponent.new(light: "wedding", dark: "wedding-dark",
                             cookie: "wedding_theme", light_value: "light",
                             dark_value: "dark", default_dark: false)
  end

  test "passes the caller's themes and cookie through to the controller" do
    render_inline(wedding_toggle)

    assert_selector "input[data-theme-toggle-component-light-value='wedding']"
    assert_selector "input[data-theme-toggle-component-dark-value='wedding-dark']"
    assert_selector "input[data-theme-toggle-component-cookie-value='wedding_theme']"
    assert_selector "input[data-theme-toggle-component-light-cookie-value='light']"
    assert_selector "input[data-theme-toggle-component-dark-cookie-value='dark']"
  end

  test "the invitation opens unchecked when the guest hasn't chosen a theme" do
    render_inline(wedding_toggle)

    assert_no_selector "input[checked]"
  end

  test "the invitation follows an explicit choice in either direction" do
    vc_test_request.cookie_jar[:wedding_theme] = "dark"
    render_inline(wedding_toggle)
    assert_selector "input[checked]"

    vc_test_request.cookie_jar[:wedding_theme] = "light"
    render_inline(wedding_toggle)
    assert_no_selector "input[checked]"
  end

  test "an unrelated cookie value falls back to the caller's default" do
    vc_test_request.cookie_jar[:light_mode] = "nonsense"

    render_inline(ThemeToggleComponent.new)

    assert_selector "input[checked]", count: 1
  end

  test "renders both swap icons and the toggle tooltip" do
    render_inline(ThemeToggleComponent.new)

    assert_selector ".tooltip[data-tip='Toggle theme']"
    assert_selector "svg.swap-off"
    assert_selector "svg.swap-on"
  end
end
