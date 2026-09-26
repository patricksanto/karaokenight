class CreateSongRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :song_requests do |t|
      t.references :room, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.string :title, null: false
      t.string :artist, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :song_requests, [:room_id, :status]
  end
end
