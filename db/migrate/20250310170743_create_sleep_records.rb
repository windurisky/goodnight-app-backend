class CreateSleepRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :sleep_records, id: false do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.references :user, type: :string, null: false
      t.datetime :clock_in_at, null: false
      t.datetime :clock_out_at
      t.integer :duration, null: false, default: 0 # in seconds
      t.string :state, null: false, default: "clocked_in"

      t.timestamps
    end

    add_index :sleep_records, %i[user_id clock_in_at]
    add_index :sleep_records, :state
  end
end
