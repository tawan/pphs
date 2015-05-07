class AddTitleToIcd9Chapters < ActiveRecord::Migration
  def change
    add_column :icd9_chapters, :title, :string
  end
end
