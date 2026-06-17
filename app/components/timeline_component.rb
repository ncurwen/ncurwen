class TimelineComponent < ViewComponent::Base
  def initialize(entries:, icon: "🌱")
    @entries = entries
    @icon = icon
  end

  def render?
    @entries.any?
  end

  private

  attr_reader :entries, :icon
end
