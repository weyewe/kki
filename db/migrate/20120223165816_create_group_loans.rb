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
      
      t.boolean :is_grace_period, :default => false 
      
      
      # our scenario: loan inspector marked the attendance (this loan inspector is supposed to be the branch manager)
      # then, it finalize the financial education attendance
      # => based on the finalization, the cashier should withdraw appropriate amount of cash, 
      # => and pass it to the field worker
      t.boolean :is_financial_education_attendance_done, :default=> false
      t.integer :financial_education_inspector_id  


      t.boolean :financial_education_finalization_proposed, :default => false 
      t.integer :financial_education_finalization_proposer_id 
    
    
      # on the loan disbursement day, the field worker has received the $$ from the cashier
      # bring that $$ to the member's house. distribute the $$$. 
      # =>  loan inspector mark the people attending the disbursement. 
      # later on the day, he will finalize the loan disbursement attendance. Cashier will be notified of the 
      # cash must be returned by the field worker
      # handle this cash offline. we are only recording the member transaction, not the internals
      
      t.boolean :loan_disbursement_finalization_proposed, :default=> false
      t.integer :loan_disbursement_finalization_proposer_id 
      
      
      # approval by loan inspector -> matching attendance.. on attendance done, 
      # => the loan disbursement transaction is created automatically. 
      t.boolean :is_loan_disbursement_attendance_done, :default => false 
      t.integer :loan_disbursement_inspector_id
    
    
      # OLD WAY
      # when loan is started, loan officer is authorized to take setup fee from member
      # cashier is authorized to take $$$
      # IS THIS CODE STILL USED ? NOPE? test it 
      # t.boolean :is_loan_disbursement_done, :default => false 
      # t.integer :loan_disburser_id 
      
      # NEW WAY
      # the field worker disbursed the loan 
      # then, matched with the loan attendance record, the appropriate amount of money should be returned to the cashier
      # NO FUCKING idea. go. have a look at the code. 
      # approval by cashier -> returning the $$$
      t.boolean :is_loan_disbursement_approved, :default => false 
      t.integer :loan_disbursement_approver_id 
      
      # START FROM LINE 246 group loan spec 
      
      # how does the flow look like?
      # 1. selected member attend the financial education
      #   those that are not present, the glm will be set to false 
          # => field worker marks attendance
                 # we need a column in glm -> field_worker_member_financial_education_attendance_status 
          # => loan inspector (usually branch manager) marks attendance 
                 # we need a column in glm -> final_member_financial_education_attendance_status 
            
            # for the group loan, we need 2 columns
                 # 1. propose_financial_education_finalization  -> field worker proposes
                 # 2. financial_education_attendance_approval    -> loan inspector decide, and approves 
                 # if no changes, follow the data entered by the field worker 
                 
            # after loan disbursement 
            # 1. propose_loan_disbursement_finalization -> will only notify the loan inspector -> finalization of attendance
                  # and disbursement  
            # 2. loan_disbursement_approval  # after loan inspector
            # if no changes, follow the data entered by field worker ( duplicate the data to final_member_loan_disbursement_attendance_status )
            
          # => loan inspector compares &&  approves the number of member attending financial education
            # => Loan inspector compares the result, negotiate, and make the final call 
            # => approve the loan. Notification is sent to cashier -> Amount of $$ to be passed to field worker 
          # => cashier withdraws $$$ equal with the amount to be disbursed to the members attending financial education 
      # 2. those attending financial education will attend loan disbursement 
      # => those that are not present will not receive the loan disbursement
      
          # => field worker marks attendance
                 # we need a column in glm -> field_worker_member_loan_disbursement_attendance_status 
          # => loan inspector (usually branch manager) marks attendance 
                 # we need a column in glm -> final_member_loan_disbursement_attendance_status   # absent or present? 
      # => loan inspector marks attendance
      # => loan inspector compares && approves the number of member attending loan disbursement (cross checked with the )
      # => account from field worker -> Out put == money needs to be returned to the cashier 
      
      
      
      # 3.  Cashier approves the loan disbursement 
        # ensuring that the cash is returned by field worker , 
        # => if the cash has not been approved, weekly collection can't be done
        
      # => Then, the weekly collection can take place .. tadaaa, really nice 
      
      
      
      
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
      # total default value generated by this group loan 
      # done 
      t.decimal :total_default_amount , :precision => 11, :scale => 2 , :default => 0 
      # 50% is paid by non defaultee + in the subgroup level, 50% is paid by the non defaultee subgroup member
      # the rest of the default is absorbed by the office as an expense 
      
      t.decimal :total_calculated_default_absorbed_by_office , :precision => 11, :scale => 2 , :default => 0  # 10^9 == 9 Billion ( max value ) all loan == default
      # the member might not be paying up to the amount.. just in case. I don't know 
      t.decimal :total_actual_default_absorbed_by_office , :precision => 11, :scale => 2 , :default => 0 
      
      # declaring that the group loan is defaulted 
      t.boolean :is_group_loan_default , :default => false 
      t.integer :default_creator_id  # no conflict resolution takes place, it is declared as default
      
      
      #after the default loan resolution
      # t.decimal :total_loss , :precision => 11, :scale => 2 , :default => 0 
      
      
      t.decimal :aggregated_principal_amount , :precision => 11, :scale => 2, :default => 0 # 10^9 == 1 Billion ( max value )
      t.decimal :aggregated_interest_amount , :precision => 10, :scale => 2, :default => 0 # 10^9== 100 million ( max value )
      # 50 members.. if  1 is borrowing 2 mi -> 100 mi
      
      t.integer :total_weeks, :default => 0 
      
      # the group_leader 
      t.integer :group_leader_id 
      
      # the business logic => group members has to be in the same commune id 
      t.integer :commune_id
      
      
      t.boolean :is_default_payment_resolution_proposed, :default => false 
      t.integer :default_payment_proposer_id 
      
      t.boolean :is_default_payment_resolution_approved, :default => false 
      t.integer :default_payment_resolution_approver_id 
      
      t.boolean :is_custom_default_payment_resolution, :default => false 
      
      # default payment
      t.decimal :default_payment_value_before_defaultee_savings_deduction , :precision => 11, :scale => 2, :default => 0
      t.decimal :default_payment_to_be_shared_among_non_defaultee , :precision => 11, :scale => 2, :default => 0
      t.decimal :group_loan_loss , :precision => 11, :scale => 2, :default => 0
      
      

      t.timestamps
    end
  end
end
