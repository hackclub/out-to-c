class AddAirtableEntryToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :airtable_entry, :string
  end
end
