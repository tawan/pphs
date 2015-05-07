class AddIcd9ChapterToDischarges < ActiveRecord::Migration
  def change
    add_column :discharges, :icd9_chapter_id, :integer
  end
end
