class RemoveIcdFromDischarges < ActiveRecord::Migration
  def change
    remove_column :discharges, :icd
  end
end
