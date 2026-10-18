class User < ApplicationRecord
  encrypts :google_refresh_token
  encrypts :google_access_token

  has_one :profile, dependent: :destroy
  has_many :captures, dependent: :destroy
  has_many :user_extension_sites, dependent: :destroy
  has_many :extension_sites, through: :user_extension_sites

  validates :name, presence: true
  validates :google_uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[user admin] }
  validates :plan_tier, inclusion: { in: %w[free premium] }

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
    user.provision_account!(profile)
    user
  end

  def admin?
    role == "admin"
  end

  def premium?
    plan_tier == "premium" && AppSetting.premium_feature_enabled?
  end

  def provision_account!(google_profile)
    sync_profile!(google_profile)
    ensure_extension_sites!
    promote_admin_from_env!
    begin
      Avatars::Generator.attach_generated!(profile)
    rescue StandardError => error
      Rails.logger.warn("Avatar generation failed: #{error.message}")
    end
  end

  def ensure_extension_sites!
    ExtensionSite.find_each do |site|
      user_extension_sites.find_or_create_by!(extension_site: site) do |preference|
        preference.enabled = site.default_enabled
      end
    end
  end

  def promote_admin_from_env!
    emails = ENV.fetch("ADMIN_EMAILS", "").split(",").map { |value| value.strip.downcase }.reject(&:blank?)
    update!(role: "admin") if emails.include?(email) && role != "admin"
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

  def sync_profile!(google_profile)
    first_name, last_name = split_google_name(google_profile)
    record = profile || build_profile(avatar_source: "generated", timezone: "Asia/Kolkata")
    record.email = email
    record.first_name = first_name if record.first_name.blank?
    record.last_name = last_name if record.last_name.blank?
    record.timezone = "Asia/Kolkata" if record.timezone.blank?
    record.save!
  end

  def split_google_name(google_profile)
    given = google_profile["given_name"].to_s.strip
    family = google_profile["family_name"].to_s.strip
    return [ given, family.presence ] if given.present?

    parts = google_profile["name"].to_s.strip.split(/\s+/, 2)
    [ parts[0].presence || email, parts[1].presence ]
  end
end
