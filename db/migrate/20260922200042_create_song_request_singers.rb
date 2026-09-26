class CreateSongRequestSingers < ActiveRecord::Migration[8.1]
  def change
    create_table :song_request_singers do |t|
      t.references :song_request, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true

      t.timestamps
    end
    add_index :song_request_singers, [:song_request_id, :participant_id], unique: true, name: "idx_song_request_singers_unique"
  end
end
