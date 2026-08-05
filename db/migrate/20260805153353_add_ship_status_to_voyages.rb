class AddShipStatusToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :ship_status, :integer
  end
end
