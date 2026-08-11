class AddDemoToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :demo, :string
  end
end
