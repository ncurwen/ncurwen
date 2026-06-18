class PagesController < ApplicationController
  def home; end
  def experience; end
  def garden; end

  def contact
    @contact_form ||= ContactForm.new
  end
end
