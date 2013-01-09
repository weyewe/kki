class AddClearVoluntarySavings < ActiveRecord::Migration
  def up
    add_column :group_loans, :is_savings_disbursement_started,  :boolean,  :default => false
    add_column :group_loans,  :savings_disbursement_starter_id  ,:integer 
    add_column :group_loans, :savings_disbursement_started_at  , :datetime
    
    add_column :group_loans, :is_savings_disbursement_finalization_proposed,  :boolean,  :default => false
    add_column :group_loans,  :savings_disbursement_finalization_proposer_id  ,:integer 
    add_column :group_loans, :savings_disbursement_finalization_proposed_at  , :datetime
    
    add_column :group_loans, :is_savings_disbursement_finalized,  :boolean,  :default => false
    add_column :group_loans,  :savings_disbursement_finalizer_id  ,:integer 
    add_column :group_loans, :savings_disbursement_finalized_at  , :datetime
    
    add_column :group_loan_memberships, :withdrawn_disbursed_savings, :decimal , :default => 0,  :precision => 9, :scale => 2
    add_column :group_loan_memberships, :saved_disbursed_savings,    :decimal , :default => 0,  :precision => 9, :scale => 2
  end

  def down
    remove_column :group_loans, :is_savings_disbursement_started  
    remove_column :group_loans,   :savings_disbursement_starter_id 
    remove_column :group_loans,  :savings_disbursement_started_at 
    
    remove_column :group_loans, :is_savings_disbursement_finalization_proposed  
    remove_column :group_loans,   :savings_disbursement_finalization_proposer_id 
    remove_column :group_loans,  :savings_disbursement_finalization_proposed_at
    
    remove_column :group_loans, :is_savings_disbursement_finalized  
    remove_column :group_loans,   :savings_disbursement_finalizer_id 
    remove_column :group_loans,  :savings_disbursement_finalized_at
    
    remove_column :group_loan_memberships, :withdrawn_disbursed_savings
    remove_column :group_loan_memberships, :saved_disbursed_savings
  end
end
