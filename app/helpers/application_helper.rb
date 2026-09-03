module ApplicationHelper
  CAREER_START = Date.new(2014, 1, 1).freeze
  def years_experience(as_of: Date.current)
    ((as_of - CAREER_START).to_i / 365.25).floor
  end

  def cli_prompt_tag(text, classes: "", caret: false)
    tag.p(class: "font-mono text-primary text-sm #{classes}".strip) do
      safe_join([
        "$ #{text}",
        (tag.span("", class: "terminal-caret", "aria-hidden": true) if caret)
      ].compact)
    end
  end

  def tooltip_tag(text, position: "top", &block)
    tag.div(class: "tooltip tooltip-#{position}", data: { tip: text }, &block)
  end

  def section_heading_tag(command:, title:, title_class: "mb-6")
    safe_join([
      cli_prompt_tag(command, classes: "mb-1"),
      tag.h2(title, class: "text-2xl font-bold #{title_class}".strip)
    ])
  end
end
