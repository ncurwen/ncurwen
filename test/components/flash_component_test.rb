require "test_helper"
require "view_component/test_helpers"

class FlashComponentTest < ViewComponent::TestCase
  test "each type gets its daisyUI alert class" do
    {
      success: "alert-success",
      error: "alert-error",
      warning: "alert-warning",
      info: "alert-info"
    }.each do |type, css_class|
      render_inline(FlashComponent.new(message: "Hello", type: type))

      assert_selector ".alert.#{css_class}", visible: :all
    end
  end

  test "each type gets its own icon" do
    {
      success: "circle-check",
      error: "circle-x",
      warning: "triangle-alert",
      info: "info"
    }.each do |type, icon|
      assert_equal icon, FlashComponent.new(message: "Hello", type: type).type_icon
    end
  end

  test "renders the message" do
    render_inline(FlashComponent.new(message: "Bob is down as coming.", type: :success))

    assert_text "Bob is down as coming."
  end

  # Rails' own flash keys are spelled as outcomes, not severities.
  test "maps Rails' notice and alert onto success and error" do
    render_inline(FlashComponent.new(message: "Signed in", type: :notice))
    assert_selector ".alert-success", visible: :all

    render_inline(FlashComponent.new(message: "Nope", type: :alert))
    assert_selector ".alert-error", visible: :all
  end

  test "good news dismisses itself, bad news waits to be read" do
    %i[success info].each do |type|
      render_inline(FlashComponent.new(message: "Hello", type: type))
      assert_selector "progress[data-flash-component-target=progress]", visible: :all
    end

    %i[error warning].each do |type|
      render_inline(FlashComponent.new(message: "Hello", type: type))
      assert_no_selector "progress", visible: :all
    end
  end

  test "an explicit auto_dismiss overrides the per-type default" do
    render_inline(FlashComponent.new(message: "Hello", type: :error, options: { auto_dismiss: true }))

    assert_selector "[data-flash-component-auto-dismiss-value=true]", visible: :all
  end

  # Turbo protects [data-turbo-permanent] nodes from removal via its
  # beforeNodeRemoved callback, so a toast survives the broadcast refreshes that
  # morph the invitation underneath it. A fresh id per render is what keeps each
  # notification a distinct node — including a repeat of the same message, which
  # is precisely the case a guest re-clicking their answer hits.
  test "every render is a distinct permanent node" do
    ids = 2.times.map do
      render_inline(FlashComponent.new(message: "Hello", type: :success))
      page.find("[data-turbo-permanent]", visible: :all)[:id]
    end

    assert_equal 2, ids.uniq.size, "identical messages must still render as separate toasts"
    assert(ids.all? { |id| id.start_with?("notification-") })
  end

  test "offers a way to dismiss it by hand" do
    render_inline(FlashComponent.new(message: "Hello", type: :success))

    assert_selector "button[data-action='flash-component#hide'][aria-label=Close]", visible: :all
  end

  test "renders an action button only when one is asked for" do
    render_inline(FlashComponent.new(message: "Hello", type: :info))
    assert_no_selector "button", text: "Undo", visible: :all

    render_inline(FlashComponent.new(message: "Hello", type: :info, options: { button_text: "Undo" }))
    assert_selector "button", text: "Undo", visible: :all
  end

  test "an unrecognised type raises rather than rendering an unstyled alert" do
    assert_raises(FlashComponent::InvalidFlashType) do
      FlashComponent.new(message: "Hello", type: :catastrophe)
    end
  end
end
