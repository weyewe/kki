class BacklogPaymentsController < ApplicationController
  def index
    @group_loan = GroupLoan.find params[:group_loan_id]
    @office = @group_loan.office
    # @backlog_payments = @group_loan.backlog_payments

    @member_with_backlog_payments = @group_loan.members.includes(:backlog_payments)
  end
  
  
  def pay_backlog_for_group_loan
    @member = Member.find_by_id params[:member_id]
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @backlog_payments = @member.backlog_payments_for_group_loan( @group_loan)
    @uncleared_backlog_payments = @member.uncleared_backlog_payments_for_group_loan( @group_loan)
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id,
      :group_loan_id => @group_loan.id 
    })
    
    @group_loan_product = @group_loan_membership.group_loan_product
   
  end
  
  
  def select_pending_backlog_to_be_approved
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @office = @group_loan.office
    @transaction_activity_backlogs_pairs  = TransactionActivity.extract_transaction_pending_backlogs_pair(@group_loan) 
    # @group_loan.pending_approval_backlogs
  end
  
  
  def execute_backlog_payment_approval_by_cashier
    @transaction= TransactionActivity.find_by_id params[:entity_id]
    @action = params[:action_value].to_i
    
    if @action == TRUE_CHECK
      @transaction.approve_backlog_payments(current_user) 
    end
    
  end
  
end
