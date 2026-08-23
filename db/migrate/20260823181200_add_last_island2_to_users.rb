class AddLastIsland2ToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_island, :integer
  end
end
