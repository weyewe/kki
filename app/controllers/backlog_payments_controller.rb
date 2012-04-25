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
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id,
      :group_loan_id => @group_loan.id 
    })
    
    @group_loan_product = @group_loan_membership.group_loan_product
   
  end
  
end
