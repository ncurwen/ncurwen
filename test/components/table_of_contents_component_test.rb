require "test_helper"
require "view_component/test_helpers"

class TableOfContentsComponentTest < ViewComponent::TestCase
  def section(id: "work", label: "Work experience", children: nil)
    s = { id: id, label: label }
    s[:children] = children if children
    s
  end

  test "renders nothing when sections are empty" do
    render_inline(TableOfContentsComponent.new(sections: []))

    assert_no_selector "[data-controller='table-of-contents-component']"
  end

  test "renders the scroll-spy aside and the mobile dropdown under one controller" do
    render_inline(TableOfContentsComponent.new(sections: [ section ]))

    assert_selector "div[data-controller='table-of-contents-component'] aside"
    assert_selector "div[data-controller='table-of-contents-component'] div.dropdown ul.menu"
  end

  test "renders a toc link per section in the desktop aside" do
    sections = [ section(id: "a", label: "A"), section(id: "b", label: "B") ]
    render_inline(TableOfContentsComponent.new(sections: sections))

    assert_selector "aside a[data-table-of-contents-component-target='link'][data-section='a'][href='#a']", text: "A"
    assert_selector "aside a[data-table-of-contents-component-target='link'][data-section='b'][href='#b']", text: "B"
  end

  test "renders nested children when present" do
    sections = [ section(children: [ { id: "work-acme", label: "Acme" } ]) ]
    render_inline(TableOfContentsComponent.new(sections: sections))

    assert_selector "aside li ul a[data-section='work-acme'][href='#work-acme']", text: "Acme"
  end

  test "omits the child list when a section has no children" do
    render_inline(TableOfContentsComponent.new(sections: [ section(children: nil) ]))

    assert_no_selector "aside li ul"
  end
end
