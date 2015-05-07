class AddYearToDischarges < ActiveRecord::Migration
  def change
    add_column :discharges, :year, :integer, :not_null => true
  end
end
