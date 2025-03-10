class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: false do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :username, limit: 20, null: false
      t.string :password_digest, null: false
      t.string :name, limit: 30, null: false

      t.timestamps
    end

    add_index :users, :username, unique: true
  end
end
