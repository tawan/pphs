class AddMeshToConditions < ActiveRecord::Migration
  def change
    add_column :conditions, :mesh, :string
  end
end
