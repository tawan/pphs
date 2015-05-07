class AddConditionsIdToDischarges < ActiveRecord::Migration
  def change
    add_column :discharges, :condition_id, :integer, :not_null => true
    remove_column :discharges, :icd_9
  end
end
