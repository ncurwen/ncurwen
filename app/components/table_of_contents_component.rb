class TableOfContentsComponent < ApplicationComponent
  # :terminal is the main site's monospace "$ goto" look. :plain drops the terminal
  # dressing so the list inherits the page's own typeface (the wedding invitation's
  # serif), and narrows the floating aside: the invitation's content runs to
  # max-w-6xl, which leaves less gutter at 2xl than the main site's max-w-4xl.
  VARIANTS = {
    terminal: { font: "font-mono", aside: "right-8 w-56" },
    plain: { font: "", aside: "right-4 w-40" }
  }.freeze

  def initialize(sections:, variant: :terminal)
    @sections = sections
    @variant = VARIANTS.fetch(variant)
    @terminal = variant == :terminal
  end

  def render?
    @sections.any?
  end

  private

  attr_reader :sections, :variant

  def terminal? = @terminal
end
