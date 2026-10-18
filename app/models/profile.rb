class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar

  validates :first_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :avatar_source, inclusion: { in: %w[generated upload] }
  validates :timezone, presence: true
  validates :phone, format: { with: /\A\+?[0-9\s\-()]{7,20}\z/ }, allow_blank: true

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
