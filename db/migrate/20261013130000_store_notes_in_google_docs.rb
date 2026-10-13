class StoreNotesInGoogleDocs < ActiveRecord::Migration[8.1]
  def change
    drop_table :notes

    reversible do |dir|
      dir.up { execute "DELETE FROM users" }
    end

    change_table :users, bulk: true do |t|
      t.string :google_uid
      t.text :google_refresh_token
      t.text :google_access_token
      t.datetime :google_token_expires_at
      t.string :google_docs_folder_id
      t.remove :password_digest, type: :string
    end

    add_index :users, :google_uid, unique: true
  end
end
