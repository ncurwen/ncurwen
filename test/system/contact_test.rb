require "application_system_test_case"

class ContactTest < ApplicationSystemTestCase
  test "submitting the form shows a success notice" do
    visit contact_path

    fill_in "your name", with: "Grace Hopper"
    fill_in "your email", with: "grace@example.com"
    fill_in "subject", with: "Hello"
    fill_in "message", with: "Nice site!"
    click_button "send →"

    assert_text "your message is on its way"
  end
end
