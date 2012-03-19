class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
      
      t.string :name 
      t.string :id_card_no
      t.integer :village_id
      t.integer :commune_id 
      t.integer :neighborhood_no
      t.text :address
      
      t.integer :creator_id  # the user with loan_officer role 
      t.integer :office_id 
        
      

      t.timestamps
    end
  end
end
