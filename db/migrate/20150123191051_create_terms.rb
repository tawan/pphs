class CreateTerms < ActiveRecord::Migration
  def change
    create_table :terms do |t|
      t.integer :condition_id
      t.string :name
    end
  end
end
