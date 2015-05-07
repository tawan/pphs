class AddIcd10Code < ActiveRecord::Migration
  def change
    add_column :icd9_chapters, :icd10, :string
  end
end
