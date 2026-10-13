class AddIndexesToNotes < ActiveRecord::Migration[8.1]
  def change
    add_index :notes, :video_id
    add_index :notes, :source
    add_index :notes, [ :user_id, :captured_at ]
  end
end
