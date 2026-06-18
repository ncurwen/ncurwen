require "test_helper"

class ContactFormModelTest < ActiveSupport::TestCase
  def valid_attrs(**overrides)
    { name: "Grace Hopper", email: "grace@example.com",
      subject: "Hello", message: "Hi there" }.merge(overrides)
  end

  test "is valid with all required attributes" do
    assert ContactForm.new(valid_attrs).valid?
  end

  test "subject is optional" do
    assert ContactForm.new(valid_attrs(subject: "")).valid?
  end

  test "requires name, email, and message" do
    form = ContactForm.new(name: "", email: "", message: "")
    assert_not form.valid?
    assert form.errors.of_kind?(:name, :blank)
    assert form.errors.of_kind?(:email, :blank)
    assert form.errors.of_kind?(:message, :blank)
  end

  test "rejects a malformed email" do
    form = ContactForm.new(valid_attrs(email: "not-an-email"))
    assert_not form.valid?
    assert form.errors.of_kind?(:email, :invalid)
  end

  test "accepts a well-formed email" do
    assert ContactForm.new(valid_attrs(email: "a.b+tag@sub.example.co.uk")).valid?
  end

  test "enforces length caps" do
    form = ContactForm.new(
      name: "a" * 101,
      email: "#{"a" * 256}@example.com",
      subject: "s" * 201,
      message: "m" * 5001
    )
    assert_not form.valid?
    assert form.errors.of_kind?(:name, :too_long)
    assert form.errors.of_kind?(:email, :too_long)
    assert form.errors.of_kind?(:subject, :too_long)
    assert form.errors.of_kind?(:message, :too_long)
  end

  test "allows attributes at their maximum length" do
    assert ContactForm.new(valid_attrs(
      name: "a" * 100,
      subject: "s" * 200,
      message: "m" * 5000
    )).valid?
  end
end
