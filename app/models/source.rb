class Source < ApplicationRecord
  has_many :captures, dependent: :restrict_with_exception

  validates :key, presence: true, uniqueness: true
  validates :name, :kind, :brand_color, presence: true

  scope :ordered, -> { order(:position, :name) }
  scope :visible, -> { where(enabled: true) }
end
