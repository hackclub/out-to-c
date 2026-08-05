class FixTypo < ActiveRecord::Migration[8.1]
  def change
    rename_column :voyages, :reviwer_note, :reviewer_note
  end
end
