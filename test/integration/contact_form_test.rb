require "test_helper"

class ContactFormTest < ActionDispatch::IntegrationTest
  test "GET /contact renders the live (non-disabled) form" do
    get contact_path
    assert_response :success
    assert_select "form[action=?][method=?]", contact_path, "post"
    assert_select "input[name=?]", "contact_form[email]"
    assert_select "fieldset[disabled]", false
  end

  test "valid submission enqueues a notification email and redirects with a notice" do
    assert_enqueued_emails 1 do
      post contact_path, params: { contact_form: {
        name: "Grace", email: "grace@example.com", subject: "Hi", message: "Hello there"
      } }
    end
    assert_redirected_to contact_path
    assert_equal "Thanks — your message is on its way. I'll be in touch soon.", flash[:notice]
  end

  test "invalid submission sends no email and re-renders with errors" do
    assert_no_enqueued_emails do
      post contact_path, params: { contact_form: {
        name: "", email: "not-an-email", subject: "", message: ""
      } }
    end
    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end
end
