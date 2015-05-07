class CreateDischarges < ActiveRecord::Migration
  def change
    create_table :discharges do |t|
      t.string :icd_9
    end
  end
end
