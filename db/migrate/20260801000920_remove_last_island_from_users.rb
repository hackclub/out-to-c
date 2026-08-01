class RemoveLastIslandFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :last_island, :integer
  end
end
