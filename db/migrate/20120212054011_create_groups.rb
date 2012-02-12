class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :creator_user_id, :null => false 
      
      t.boolean :is_closed, :default => false 
      t.integer :group_closer_id
      
      t.boolean :is_started, :default => false 
      t.integer :group_starter_id # when loan is disbursed, it is started, can't add new members
      
      t.integer :total_deposit # auto calculate when the group is started
      
      
      t.integer :total_default
      t.boolean :any_default , :default => false 
      t.integer :default_creator_id  # no conflict resolution takes place, it is declared as default
      
      
      

      t.timestamps
    end
  end
end
