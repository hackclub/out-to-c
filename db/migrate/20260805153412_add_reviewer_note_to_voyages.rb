class AddReviewerNoteToVoyages < ActiveRecord::Migration[8.1]
  def change
    add_column :voyages, :reviwer_note, :string
  end
end
