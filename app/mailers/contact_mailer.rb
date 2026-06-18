class ContactMailer < ApplicationMailer
  def notification(name:, email:, subject:, message:)
    @name = name
    @email = email
    @subject = subject.presence || "(no subject)"
    @message = message

    mail(
      to: "the.only.nick.curwen@gmail.com",
      reply_to: email,
      subject: "[ncurwen.dev] #{@subject}"
    )
  end
end
