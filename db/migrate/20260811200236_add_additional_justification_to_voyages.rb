class AddAdditionalJustificationToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :additional_justification, :string
  end
end
