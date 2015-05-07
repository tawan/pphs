class AddWeightToDischarges < ActiveRecord::Migration
  def change
    add_column :discharges, :weight, :integer, :not_null => true
  end
end
