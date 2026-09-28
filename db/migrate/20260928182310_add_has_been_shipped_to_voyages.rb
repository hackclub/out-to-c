class AddHasBeenShippedToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :has_been_shipped, :boolean
  end
end
