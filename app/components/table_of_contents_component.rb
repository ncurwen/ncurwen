class TableOfContentsComponent < ViewComponent::Base
  def initialize(sections:)
    @sections = sections
  end

  def render?
    @sections.any?
  end

  private

  attr_reader :sections
end
