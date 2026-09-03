class CreateGuests < ActiveRecord::Migration[8.1]
  def change
    create_table :guests do |t|
      t.string :token,  null: false
      t.string :name,   null: false
      t.string :group,  null: false
      t.string :status, null: false, default: "unknown"

      t.timestamps
    end

    add_index :guests, :token, unique: true
    add_index :guests, %i[group name]
  end
end
