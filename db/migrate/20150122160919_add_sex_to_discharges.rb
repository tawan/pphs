class AddSexToDischarges < ActiveRecord::Migration
  def change
    add_column :discharges, :sex, :integer, :not_null => true
  end
end
