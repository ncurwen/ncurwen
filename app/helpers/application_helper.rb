module ApplicationHelper
  CAREER_START = Date.new(2014, 1, 1).freeze
  def years_experience(as_of: Date.current)
    ((as_of - CAREER_START).to_i / 365.25).floor
  end

  def cli_prompt_tag(text, classes: "")
    tag.p("$ #{text}", class: "font-mono text-primary text-sm #{classes}".strip)
  end

  def section_heading_tag(command:, title:, title_class: "mb-6")
    safe_join([
      cli_prompt_tag(command, classes: "mb-1"),
      tag.h2(title, class: "text-2xl font-bold #{title_class}".strip)
    ])
  end
end
