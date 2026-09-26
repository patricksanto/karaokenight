class CreatePerformanceSingers < ActiveRecord::Migration[8.1]
  def change
    create_table :performance_singers do |t|
      t.references :performance, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true

      t.timestamps
    end
    add_index :performance_singers, [:performance_id, :participant_id], unique: true, name: "idx_performance_singers_unique"
  end
end
