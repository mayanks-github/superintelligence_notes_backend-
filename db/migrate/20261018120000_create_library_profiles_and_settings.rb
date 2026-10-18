class CreateLibraryProfilesAndSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "user"
    add_column :users, :plan_tier, :string, null: false, default: "free"

    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :first_name, null: false
      t.string :last_name
      t.string :email, null: false
      t.string :phone
      t.string :timezone, null: false, default: "Asia/Kolkata"
      t.string :bio
      t.string :avatar_source, null: false, default: "generated"
      t.timestamps
    end
    add_index :profiles, :email

    create_table :sources do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :kind, null: false
      t.string :host
      t.string :brand_color, null: false
      t.boolean :supports_watch, null: false, default: false
      t.boolean :supports_manual_paste, null: false, default: true
      t.boolean :extension_capturable, null: false, default: false
      t.boolean :enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :sources, :key, unique: true

    create_table :captures do |t|
      t.references :user, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true
      t.string :title, null: false
      t.string :origin, null: false
      t.text :summary_text
      t.string :google_doc_id
      t.string :external_url
      t.string :video_id
      t.string :video_url
      t.string :video_title
      t.string :thumbnail_url
      t.datetime :saved_at, null: false
      t.string :storage, null: false, default: "google_docs"
      t.timestamps
    end
    add_index :captures, [ :user_id, :saved_at ]
    add_index :captures, [ :user_id, :source_id, :saved_at ]
    add_index :captures, [ :user_id, :google_doc_id ], unique: true

    create_table :extension_sites do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :match_pattern, null: false
      t.string :aliases, array: true, null: false, default: []
      t.boolean :default_enabled, null: false, default: false
      t.boolean :enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :extension_sites, :key, unique: true

    create_table :user_extension_sites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :extension_site, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: false
      t.timestamps
    end
    add_index :user_extension_sites, [ :user_id, :extension_site_id ], unique: true, name: "index_user_extension_sites_uniqueness"

    create_table :app_settings do |t|
      t.string :key, null: false
      t.jsonb :value, null: false, default: {}
      t.timestamps
    end
    add_index :app_settings, :key, unique: true
  end
end
