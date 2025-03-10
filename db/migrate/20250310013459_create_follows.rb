class CreateFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :follows, id: false do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :follower_id, limit: 36, null: false
      t.string :followed_id, limit: 36, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :follows, %i[follower_id followed_id], unique: true
    add_index :follows, %i[active follower_id]
    add_index :follows, %i[active followed_id]
  end
end
