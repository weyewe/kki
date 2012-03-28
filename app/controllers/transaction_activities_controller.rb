class TransactionActivitiesController < ApplicationController
  
  def create_transaction_activity_for_setup_payment
    admin_fee = BigDecimal.new( params[:admin_fee] )
    initial_savings = BigDecimal.new( params[:initial_savings] )
    deposit = BigDecimal.new( params[:deposit] )
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:group_loan_membership_id] )

    @transaction_activity = TransactionActivity.create_setup_payment( admin_fee, initial_savings,
              deposit, current_user, @group_loan_membership )
  end
  
  
  def execute_loan_disbursement
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:entity_id] )
    @transaction_activity = TransactionActivity.execute_loan_disbursement( @group_loan_membership , current_user)
  end
  
  
end
