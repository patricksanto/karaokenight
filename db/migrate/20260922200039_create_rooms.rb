class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :code, null: false
      t.string :name
      t.integer :status, null: false, default: 0
      t.string :host_token_digest, null: false
      t.text :settings

      t.timestamps
    end
    add_index :rooms, :code, unique: true
  end
end
