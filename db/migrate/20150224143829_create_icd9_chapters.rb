class CreateIcd9Chapters < ActiveRecord::Migration
  def change
    create_table :icd9_chapters do |t|
      t.string :code
      t.string :mesh
    end
  end
end
