class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :video_id
      t.string :video_title
      t.string :video_url
      t.text :summary_text
      t.string :source
      t.jsonb :sections
      t.datetime :captured_at

      t.timestamps
    end
  end
end
