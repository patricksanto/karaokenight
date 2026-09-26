class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :performance, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.integer :score, null: false
      t.text :message
      t.datetime :hidden_at

      t.timestamps
    end
    add_index :votes, [:performance_id, :participant_id], unique: true
  end
end
