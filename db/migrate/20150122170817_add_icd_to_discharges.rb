class AddIcdToDischarges < ActiveRecord::Migration
  def change
    add_column :discharges, :icd, :string, :not_null => true, :limit => 5
  end
end
