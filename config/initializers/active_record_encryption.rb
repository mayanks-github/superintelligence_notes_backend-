encryption = Rails.application.config.active_record.encryption

if encryption.primary_key.blank?
  secret = Rails.application.secret_key_base.to_s
  encryption.primary_key = Digest::SHA256.hexdigest("ar-primary-#{secret}")
  encryption.deterministic_key = Digest::SHA256.hexdigest("ar-deterministic-#{secret}")
  encryption.key_derivation_salt = Digest::SHA256.hexdigest("ar-salt-#{secret}")
end
