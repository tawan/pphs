class CreateConditions < ActiveRecord::Migration
  def change
    create_table :conditions do |t|
      t.string :icd_9
    end
  end
end
