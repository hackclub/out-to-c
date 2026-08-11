class AddHackatimeIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :hackatime_id, :integer
  end
end
