require "test_helper"
require "view_component/test_helpers"

class CopyComponentTest < ViewComponent::TestCase
  test "wires the value the Stimulus controller copies" do
    render_inline(CopyComponent.new(label: "email", value: "contact@ncurwen.dev"))

    assert_selector "[data-controller='copy-component'][data-copy-component-text-value='contact@ncurwen.dev']"
    assert_selector "button[data-action='copy-component#copy'][aria-label='Copy email address']"
  end

  test "renders the label, value, and the toast target the controller reveals" do
    render_inline(CopyComponent.new(label: "email", value: "contact@ncurwen.dev"))

    assert_text "email"
    assert_text "contact@ncurwen.dev"
    assert_selector "[data-copy-component-target='toast']"
    assert_selector "[data-copy-component-target='message']"
  end
end
