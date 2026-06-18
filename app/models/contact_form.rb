class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :subject, :string
  attribute :message, :string

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    length: { maximum: 255 }
  validates :subject, length: { maximum: 200 }
  validates :message, presence: true, length: { maximum: 5000 }
end
