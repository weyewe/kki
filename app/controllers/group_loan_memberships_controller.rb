class GroupLoanMembershipsController < ApplicationController
  
  def new
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
    @commune_members = @group_loan.commune.members
  end
  
  
  def create
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js
    end
  end
  
end
