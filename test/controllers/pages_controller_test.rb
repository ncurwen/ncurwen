require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET /garden renders gallery section, cli prompts, and timeline" do
    get garden_path

    assert_response :success

    assert_select "section[data-controller='gallery']"
    assert_select "section[data-controller='gallery'][data-gallery-images-value]"
    assert_select "ul.timeline.timeline-vertical"
    assert_select "ul.timeline > li"

    body = @response.body
    assert_includes body, "$ tail -n 4 garden.log"
    assert_includes body, "$ ls images/garden/"
    assert_includes body, "$ cat garden.log"
    assert_match(/<span[^>]*>\s*head\s*<\/span>/, body)
  end

  test "GET /experience renders toc, section headings, and work/education cards" do
    get experience_path

    assert_response :success

    assert_select "aside[data-controller='toc']"
    assert_select "section#work article.card"
    assert_select "section#education article.card"

    body = @response.body
    assert_includes body, "$ cat resume.txt"
    assert_includes body, "$ history --work"
    assert_includes body, "$ cat education.txt"
  end
end
