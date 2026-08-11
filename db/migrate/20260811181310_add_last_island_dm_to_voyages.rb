class AddLastIslandDmToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :last_island_dm, :integer
  end
end
