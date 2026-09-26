class CreateReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :reactions do |t|
      t.references :performance, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.string :kind, null: false

      t.timestamps
    end

    add_index :reactions, [:performance_id, :kind]
  end
end
