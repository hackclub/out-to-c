class AddOwnerToVoyage < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :owner, :integer
  end
end
