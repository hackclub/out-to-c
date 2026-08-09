class AddJustificationToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :justification, :string
  end
end
