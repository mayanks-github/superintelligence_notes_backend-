class ExtensionSite < ApplicationRecord
  has_many :user_extension_sites, dependent: :destroy

  validates :key, :name, :match_pattern, presence: true
  validates :key, uniqueness: true

  scope :ordered, -> { order(:position, :name) }
end
