class CreateVillages < ActiveRecord::Migration
  def change
    create_table :villages do |t|
      t.string :name
      t.integer :subdistrict_id 
      t.string :postal_code

      t.timestamps
    end
  end
end
