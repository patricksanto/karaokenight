class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :room, null: false, foreign_key: true
      t.string :nickname, null: false
      t.string :emoji, null: false, default: "🎤"
      t.string :session_token_digest, null: false
      t.boolean :available, null: false, default: true
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :participants, [:room_id, :nickname], unique: true
  end
end
