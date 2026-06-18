class ContactFormsController < ApplicationController
  def create
    @contact_form = ContactForm.new(contact_form_params)

    if @contact_form.valid?
      ContactMailer.notification(
        name: @contact_form.name,
        email: @contact_form.email,
        subject: @contact_form.subject,
        message: @contact_form.message
      ).deliver_later
      redirect_to contact_path, notice: "Thanks — your message is on its way. I'll be in touch soon."
    else
      flash.now[:alert] = "Please fix the errors below and try again."
      render "pages/contact", status: :unprocessable_entity
    end
  end

  private

  def contact_form_params
    params.require(:contact_form).permit(:name, :email, :subject, :message)
  end
end
