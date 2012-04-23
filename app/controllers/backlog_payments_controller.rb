class BacklogPaymentsController < ApplicationController
  def index
    @group_loan = GroupLoan.find params[:group_loan_id]
    @office = @group_loan.office
    @backlog_payments = @group_loan.backlog_payments
   
  end
  
end
