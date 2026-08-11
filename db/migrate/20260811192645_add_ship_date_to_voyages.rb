class AddShipDateToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :ship_date, :date
  end
end
