class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :creator_user_id, :null => false 
      t.integer :group_loan_id
      t.integer :loan_assignment_creator_id 
      
      t.boolean :is_closed, :default => false 
      t.integer :group_closer_id  
      # at the end of the loan cycle, the group will be closed
      # => by the branch manager
      # => any outstanding debt will be taken care of based on the agreement
      # => initial deposit + savings deduction
      
      t.boolean :is_started, :default => false 
      t.integer :group_starter_id # when loan is disbursed, it is started, can't add new members
      
      t.integer :total_deposit # auto calculate when the group is started
      t.integer :total_initial_saving
      t.integer :total_admin_fee 
      t.integer :total_deposit_approver_id 
      t.integer :total_deposit_approver_id 
      t.integer :total_deposit_approver_id 
      
      t.boolean :total_deposit_approval  , :default => false 
      t.boolean :total_deposit_approval , :default => false 
      t.boolean :total_deposit_approval , :default => false 
      
      t.integer :total_default
      t.boolean :any_default , :default => false 
      t.integer :default_creator_id  # no conflict resolution takes place, it is declared as default
      
      
      t.integer :commune_id 
      

      t.timestamps
    end
  end
end
