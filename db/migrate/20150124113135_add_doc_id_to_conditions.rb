class AddDocIdToConditions < ActiveRecord::Migration
  def change
    add_column :conditions, :doc_id, :string
  end
end
