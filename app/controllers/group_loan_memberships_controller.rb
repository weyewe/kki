class GroupLoanMembershipsController < ApplicationController
  
  def new
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
    @commune_members = @group_loan.commune.members
  end
  
  
=begin
  Business logic => people staying in the same subdistrict can apply for the group loan
  No simultaneous group loan 
=end
  def create
    # "membership_provider"=>"4", "membership_consumer"=>"1", "membership_decision"=>"1"}
    @decision = params[:membership_decision].to_i
    @group_loan = GroupLoan.find_by_id params[:membership_provider]
    @member = Member.find_by_id params[:membership_consumer]
    @new_group_loan_membership = ''
    
  
    if @decision == TRUE_CHECK
      @new_group_loan_membership = GroupLoanMembership.create_membership( current_user,
                                  @member, @group_loan)
    elsif @decision == FALSE_CHECK
      @new_group_loan_membership = GroupLoanMembership.destroy_membership( current_user, 
                                  @member, @group_loan )
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js
    end
  end
  
=begin
  For Field Worker to take setup fee 
=end

  def group_loan_memberships_for_setup_fee
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id] )
    @group_loan_memberships = @group_loan.group_loan_memberships.order("created_at DESC")
  end
  
end
