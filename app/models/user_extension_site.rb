class UserExtensionSite < ApplicationRecord
  belongs_to :user
  belongs_to :extension_site

  validates :extension_site_id, uniqueness: { scope: :user_id }
end
