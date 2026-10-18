class AppSetting < ApplicationRecord
  PREMIUM_FEATURE = "premium_feature_enabled"

  validates :key, presence: true, uniqueness: true

  def self.premium_feature_enabled?
    raw = find_by(key: PREMIUM_FEATURE)&.value
    return true if raw.nil?

    enabled = raw.is_a?(Hash) ? raw["enabled"] : raw
    ActiveModel::Type::Boolean.new.cast(enabled)
  end

  def self.set_premium_feature_enabled!(enabled)
    record = find_or_initialize_by(key: PREMIUM_FEATURE)
    record.value = { "enabled" => ActiveModel::Type::Boolean.new.cast(enabled) }
    record.save!
    record
  end
end
