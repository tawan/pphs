class AddIndexedToConditions < ActiveRecord::Migration
  def change
    add_column :conditions, :indexed, :boolean, :not_null => true, :default => false
  end
end
