class AddSecondsOffsetToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :seconds_offset, :integer
  end
end
