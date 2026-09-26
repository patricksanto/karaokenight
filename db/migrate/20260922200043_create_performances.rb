class CreatePerformances < ActiveRecord::Migration[8.1]
  def change
    create_table :performances do |t|
      t.references :room, null: false, foreign_key: true
      t.references :song_request, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :voting_closes_at
      t.datetime :revealed_at
      t.decimal :average_score, precision: 4, scale: 1
      t.integer :votes_count, default: 0
      t.text :messages_order

      t.timestamps
    end
    add_index :performances, [:room_id, :status]
  end
end
