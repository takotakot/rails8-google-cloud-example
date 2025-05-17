class CreateCounters < ActiveRecord::Migration[7.1]
  def change
    create_table :counters, id: false do |t|
      t.string :id, primary_key: true
      t.integer :count, null: false, default: 0
    end
  end
end
