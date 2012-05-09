class DefaultPaymentsController < ApplicationController
  def list_default_payment_for_clearance
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @default_payments = @group_loan.default_payments
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_for_loan_default_resolution_path'
    set_breadcrumb_for @group_loan, 'list_default_payment_for_clearance_url' + "(#{@group_loan.id})", 
                "Select Backlog"
    
  end
  
  def payment_for_default_resolution
    @default_payment = DefaultPayment.find_by_id params[:default_payment_id]
  end
end
