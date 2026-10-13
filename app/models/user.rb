class User < ApplicationRecord
  encrypts :google_refresh_token
  encrypts :google_access_token

  validates :name, presence: true
  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :normalize_email

  def self.from_google!(profile, tokens)
    email = profile["email"].to_s.strip.downcase
    raise Google::Error, "Google did not share a verified email address." if email.blank? || profile["email_verified"] != true

    user = find_by(google_uid: profile["sub"]) || find_or_initialize_by(email: email)
    user.google_uid = profile["sub"]
    user.email = email
    user.name = profile["name"].presence || email
    user.google_refresh_token = tokens["refresh_token"] if tokens["refresh_token"].present?
    raise Google::Error, "Google did not grant offline access. Sign in again and allow access." if user.google_refresh_token.blank?

    user.google_access_token = tokens["access_token"]
    user.google_token_expires_at = Time.current + tokens.fetch("expires_in", 3600).to_i.seconds
    user.save!
    user
  end

  def google_access_token!
    if google_access_token.present? && google_token_expires_at.present? && google_token_expires_at > 1.minute.from_now
      return google_access_token
    end

    raise Google::Error, "Sign in with Google again to allow Docs access." if google_refresh_token.blank?

    tokens = Google::Oauth.refresh(google_refresh_token)
    update!(
      google_access_token: tokens.fetch("access_token"),
      google_token_expires_at: Time.current + tokens.fetch("expires_in", 3600).to_i.seconds,
      google_refresh_token: tokens["refresh_token"].presence || google_refresh_token
    )
    google_access_token
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
