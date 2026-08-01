class AddLastIslandToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :last_island, :integer
  end
end
