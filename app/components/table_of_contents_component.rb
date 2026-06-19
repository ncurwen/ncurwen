class TableOfContentsComponent < ApplicationComponent
  def initialize(sections:)
    @sections = sections
  end

  def render?
    @sections.any?
  end

  private

  attr_reader :sections
end
