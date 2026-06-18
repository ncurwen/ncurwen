require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "notification sets headers and body" do
    mail = ContactMailer.notification(
      name: "Grace", email: "grace@example.com", subject: "Hello", message: "A message"
    )

    assert_equal [ "the.only.nick.curwen@gmail.com" ], mail.to
    assert_equal [ "contact@ncurwen.dev" ], mail.from
    assert_equal [ "grace@example.com" ], mail.reply_to
    assert_equal "[ncurwen.dev] Hello", mail.subject
    assert_match "Grace", mail.body.encoded
    assert_match "A message", mail.body.encoded
  end

  test "blank subject falls back to a placeholder" do
    mail = ContactMailer.notification(name: "G", email: "g@h.com", subject: "", message: "hi")
    assert_equal "[ncurwen.dev] (no subject)", mail.subject
  end
end
