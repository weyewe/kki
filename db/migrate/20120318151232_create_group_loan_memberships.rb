class CreateGroupLoanMemberships < ActiveRecord::Migration
  def change
    create_table :group_loan_memberships do |t|
      t.integer :group_loan_id 
      t.integer :member_id 
      # t.integer :membership_creator_id  # just store it in the major database 
      
      # t.integer :loan_subcription_
      #     t.integer :loan_product_creator_id 
      
     
      t.decimal :deposit, :default => 0,  :precision => 9, :scale => 2 # 10^7 == at most 10 mi rupiah 
      t.decimal :initial_savings, :default => 0,  :precision => 9, :scale => 2 # 10^7 == at most 10 mi rupiah 
      t.decimal :admin_fee, :default => 0,  :precision => 9, :scale => 2 # 10^7 == at most 10 mi rupiah 
      
      # t.integer :initial_deposit_creator_id   store in the activity table 
      #     t.integer :initial_saving_creator_id
      #     t.integer :admin_fee_creator_id
      t.boolean :has_paid_setup_fee, :default => false 
      t.integer :setup_fee_transaction_id 
      
      
      t.integer :loan_disbursement_transaction_id 
      t.boolean :has_received_loan_disbursement, :default => false 
      t.integer :loan_disburser_id 
      
      
      t.boolean :deduct_setup_payment_from_loan , :default => false 
      t.integer :sub_group_id 
      # t.datetime :sub_group_update_datetime 
      
      
      t.boolean :is_attending_financial_lecture
      t.integer :financial_lecture_attendance_marker_id
      
      t.boolean :final_financial_lecture_attendance
      t.integer :final_financial_lecture_attendance_marker_id 
      
      t.boolean :is_attending_loan_disbursement
      t.integer :loan_disbursement_attendance_marker_id  
      
      t.boolean :final_loan_disbursement_attendance
      t.integer :final_loan_disbursement_attendance_marker_id
      
      t.boolean :is_active , :default => true 
      t.integer :deactivation_case , :default => nil # GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE, deactivation reason
      
      t.boolean :is_compulsory_savings_migrated, :default => false 
      
    
      
      
      # if the member has no sufficient $$ to pay for weekly payment
      # and, doesn't intend to use the saving || the saving is not enough to cover for the remnant
      # t.boolean :backlog_payment , :default => false 

      t.timestamps
      
    end
  end
end
