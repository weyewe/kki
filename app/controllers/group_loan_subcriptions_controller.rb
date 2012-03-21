class GroupLoanSubcriptionsController < ApplicationController
  def new
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
    @group_loan_members = @group_loan.members
    # @group_loan_products_used = @group_loan.all_group_loan_products_used
    @group_loan_products = @office.group_loan_products
  end
  
  
end
