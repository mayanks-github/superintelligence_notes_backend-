class Capture < ApplicationRecord
  ORIGINS = %w[extension manual].freeze
  STORAGES = %w[google_docs both].freeze

  belongs_to :user
  belongs_to :source

  validates :title, :origin, :saved_at, presence: true
  validates :origin, inclusion: { in: ORIGINS }
  validates :storage, inclusion: { in: STORAGES }
  validates :google_doc_id, uniqueness: { scope: :user_id }, allow_nil: true

  scope :newest, -> { order(saved_at: :desc) }
  scope :oldest, -> { order(saved_at: :asc) }
end
