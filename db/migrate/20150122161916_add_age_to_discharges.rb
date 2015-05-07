class AddAgeToDischarges < ActiveRecord::Migration
  def change
    add_column :discharges, :age_unit, :integer, :not_null => true
    add_column :discharges, :age, :integer, :not_null => true
  end
end
