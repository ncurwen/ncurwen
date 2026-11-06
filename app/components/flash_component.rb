class FlashComponent < ApplicationComponent
  class InvalidFlashType < StandardError; end

  # Checked *after* map_flash_type has run, so :alert and :notice are
  # deliberately absent — by then they've already become :error and :success.
  ALLOWED_FLASH_TYPES = %i[success warning error info].freeze

  ACTION_BUTTON_CLASSES = "btn btn-sm btn-outline-black"

  attr_reader :message, :type, :icon_hide, :auto_dismiss, :button_text, :button_action

  def initialize(message:, type:, options: {})
    data = normalize_input(message.is_a?(Hash) ? message : options)
    @message = data[:message] || message
    @type = map_flash_type(type.to_sym)
    @icon_hide = icon_visibility(data[:icon_hide])
    @auto_dismiss = data[:auto_dismiss] || %i[success info].include?(@type)
    @button_text = data[:button_text]
    @button_action = data[:button_action]

    validate_type
  end

  # Hash Map of Daisy alert classes for Tailwind JIT compatibility (v.s. interpolation)
  def type_class
    {
      error: "alert-error",
      success: "alert-success",
      warning: "alert-warning",
      info: "alert-info"
    }[@type]
  end

  def type_icon
    {
      error: "circle-x",
      success: "circle-check",
      warning: "triangle-alert",
      info: "info"
    }[@type]
  end

  def action_button
    action_button_option
  end

  private

  def validate_type
    return if ALLOWED_FLASH_TYPES.include?(type)

    exception = InvalidFlashType.new(
      "Invalid flash type: #{type}. Allowed types: #{ALLOWED_FLASH_TYPES.join(', ')}"
    )
    Rails.env.local? ? raise(exception) : Rollbar.error(exception)
  end

  # Rails' own :notice/:alert (and Devise's, which reuses them) are spelled as
  # outcomes rather than severities. Fold them into the four we style.
  def map_flash_type(type)
    case type
    when :alert  then :error
    when :notice then :success
    else type
    end
  end

  def icon_visibility(icon_hide)
    return unless icon_hide

    "!hidden"
  end

  def action_button_option
    return if @button_text.blank?

    tag.div(class: "w-fit mt-2") do
      button_tag(@button_text, class: ACTION_BUTTON_CLASSES, data: { turbo: false, action: @button_action })
    end
  end

  def normalize_input(input)
    return { message: input }.with_indifferent_access unless input.is_a?(Hash)

    input.with_indifferent_access
  end
end
