class TransactionActivitiesController < ApplicationController
  def create_transaction_activity_for_setup_payment
    # sleep 2 
    
    # "group_loan_membership_id"=>"1", "admin_fee"=>"25000", "initial_savings"=>"15000", "deposit"=>"2432432"
    
    admin_fee = BigDecimal.new( params[:admin_fee] )
    initial_savings = BigDecimal.new( params[:initial_savings] )
    deposit = BigDecimal.new( params[:deposit] )
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:group_loan_membership_id] )

    @transaction_activity = TransactionActivity.create_setup_payment( admin_fee, initial_savings,
              deposit, current_user, @group_loan_membership )
  end
  
  
end
