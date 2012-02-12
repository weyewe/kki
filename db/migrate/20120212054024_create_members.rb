class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
      
      t.string :name 
      t.string :id_card_no
      t.integer :village_id
      t.integer :commune_id 
      t.integer :neighborhood_no
      t.text :address
      
      t.integer :member_creator_id 
      
      

      t.timestamps
    end
  end
end
