class CreateGroupLoans < ActiveRecord::Migration
  def change
    create_table :group_loans do |t|
      t.string :name
      t.integer :creator_id, :null => false  # it should be the user with role LoanOfficer
      t.integer :office_id
      
      t.boolean :is_closed, :default => false 
      t.integer :group_loan_closer_id  
      # at the end of the loan cycle, the group will be closed
      # => by the branch manager
      # => any outstanding debt will be taken care of based on the agreement
      # => initial deposit + savings deduction
      
      t.boolean :is_started, :default => false 
      t.integer :group_loan_starter_id 
      # when loan is started, loan officer is authorized to take setup fee from member
      # cashier is authorized to take $$$ 
      
      
      t.boolean :is_loan_disbursement_done, :default => false 
      t.integer :loan_disburser_id 
      # when loan is started, loan officer is authorized to take setup fee from member
      # cashier is authorized to take $$$
      
      
      t.boolean :is_setup_fee_collection_finalized, :default => false 
      t.integer :setup_fee_collection_finalizer_id
      # when all setup payment from all members have been collected,
      # the field_worker has to finalize such activity by clicking the button.
      
      t.boolean :is_setup_fee_collection_approved, :default => false 
      t.integer :setup_fee_collection_approver_id
      # the cashier has to approve the setup fee collection (the amount)
      # the fee collection is recorded in the group_loan_membership << field worker's id
      
      # loan officer has to propose the group_loan 
      t.boolean :is_proposed, :default => false 
      t.integer :group_loan_proposer_id # when loan is disbursed, it is started, can't add new members
  
      
      # t.decimal :total_deposit,  :precision => 11, :scale => 2 , :default => 0   # 10^9 == 9 Billion ( max value )  
      t.decimal :total_default , :precision => 11, :scale => 2 , :default => 0  # 10^9 == 9 Billion ( max value ) all loan == default
      t.boolean :is_group_loan_default , :default => false 
      t.integer :default_creator_id  # no conflict resolution takes place, it is declared as default
      
      #after the default loan resolution
      t.decimal :total_loss , :precision => 11, :scale => 2 , :default => 0 
      
      
      t.decimal :aggregated_principal_amount , :precision => 11, :scale => 2, :default => 0 # 10^9 == 1 Billion ( max value )
      t.decimal :aggregated_interest_amount , :precision => 10, :scale => 2, :default => 0 # 10^9== 100 million ( max value )
      # 50 members.. if  1 is borrowing 2 mi -> 100 mi
      
      
      # the group_leader 
      t.integer :group_leader_id 
      
      # the business logic => group members has to be in the same commune id 
      t.integer :commune_id
      
      

      t.timestamps
    end
  end
end
