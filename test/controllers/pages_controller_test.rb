require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET / renders the hero and links to the main sections" do
    get root_path

    assert_response :success

    assert_select "h1", text: /Hi, I'm Nick Curwen/
    assert_select "[data-controller='typewriter']"
    assert_select "a[href=?]", experience_path
    assert_select "a[href=?]", garden_path
    assert_select "a[href=?]", contact_path
  end

  test "GET /garden wires the real gallery data into the photo gallery section" do
    get garden_path

    assert_response :success

    assert_select "section[data-controller~='photo-gallery-filter-component']"
    assert_select "section[data-controller~='photo-gallery-filter-component'][data-photo-gallery-filter-component-images-value]"
  end

  test "GET /experience renders the TOC, section headings, and one entry per data row" do
    get experience_path

    assert_response :success

    assert_select "div[data-controller='table-of-contents-component']"

    assert_select "h1", text: "Experience"
    assert_select "#featured h2", text: "Featured project"
    assert_select "#skills h2", text: "Skills"
    assert_select "section#work h2", text: "Work history"
    assert_select "section#education h2", text: "Education"

    assert_select "section#work article.timeline-entry", count: SiteData.fetch(:work_history).size
    assert_select "section#education article.card", count: SiteData.fetch(:education).size
  end
end
