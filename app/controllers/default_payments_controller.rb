class DefaultPaymentsController < ApplicationController
  def list_default_payment_for_clearance
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @default_payments = @group_loan.default_payments
  end
end
