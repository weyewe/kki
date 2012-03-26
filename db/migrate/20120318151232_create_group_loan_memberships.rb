class CreateGroupLoanMemberships < ActiveRecord::Migration
  def change
    create_table :group_loan_memberships do |t|
      t.integer :group_loan_id 
      t.integer :member_id 
      # t.integer :membership_creator_id  # just store it in the major database 
      
      # t.integer :loan_subcription_
      #     t.integer :loan_product_creator_id 
      
     
      t.decimal :deposit, :default => 0,  :precision => 9, :scale => 2 # 10^7 == at most 10 mi rupiah 
      
      # t.integer :initial_deposit_creator_id   store in the activity table 
      #     t.integer :initial_saving_creator_id
      #     t.integer :admin_fee_creator_id
      
      
      
      # if the member has no sufficient $$ to pay for weekly payment
      # and, doesn't intend to use the saving || the saving is not enough to cover for the remnant
      # t.boolean :backlog_payment , :default => false 

      t.timestamps
      
    end
  end
end
