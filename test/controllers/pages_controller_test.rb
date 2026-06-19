require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET /garden renders the photo gallery section with embedded data" do
    get garden_path

    assert_response :success

    assert_select "section[data-controller~='photo-gallery-filter-component']"
    assert_select "section[data-controller~='photo-gallery-filter-component'][data-photo-gallery-filter-component-images-value]"

    assert_includes @response.body, "$ tail -f garden.log"
  end

  test "GET /experience renders the TOC, section headings, and work/education entries" do
    get experience_path

    assert_response :success

    assert_select "div[data-controller='table-of-contents-component']"
    assert_select "section#work article.timeline-entry"
    assert_select "section#education article.card"

    body = @response.body
    assert_includes body, "$ cat resume.txt"
    assert_includes body, "$ history --work"
    assert_includes body, "$ cat education.txt"
  end
end
