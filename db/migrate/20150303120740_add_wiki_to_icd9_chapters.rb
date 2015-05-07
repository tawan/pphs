class AddWikiToIcd9Chapters < ActiveRecord::Migration
  def change
    add_column :icd9_chapters, :wiki, :text
  end
end
