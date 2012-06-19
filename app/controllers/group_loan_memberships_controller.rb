class GroupLoanMembershipsController < ApplicationController
  
  def new
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
    @commune_members = @group_loan.commune.members.order("created_at ASC")
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_to_assign_member_url'
    set_breadcrumb_for @group_loan, 'new_group_loan_group_loan_membership_url' + "(#{@group_loan.id})", 
                "Assign Group Loan"
                
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
  For Field Worker to take setup fee : cash and loan deduction 
=end

  def group_loan_memberships_for_setup_fee
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id] )
    @group_loan_memberships = @group_loan.group_loan_memberships.order("created_at DESC")
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_for_setup_payment_url'
    set_breadcrumb_for @group_loan, 'group_loan_memberships_for_setup_fee_url' + "(#{@group_loan.id})", 
                "Select Backlog"
                
  end
  
  # declare that the setup payment will be taken from the loan
  def declare_setup_payment_by_loan_deduction
    @office = current_user.active_job_attachment.office
    @group_loan_membership = GroupLoanMembership.find params[:group_loan_membership_id]
    # we need to check whether such group loan membership can be updated by current user
    # Field Worker Task assignment : assigning responsibility between field_worker and  the group loan 
    @group_loan_membership.declare_setup_payment_by_loan_deduction
    
  end
  
  
=begin
  Marking The FINANCIAL EDUCATION ATTENDANCE
=end
  def execute_financial_attendance_marking
    @group_loan_membership  = GroupLoanMembership.find_by_id params[:entity_id]
    @group_loan = @group_loan_membership.group_loan
    
    if params[:action_value].to_i == TRUE_CHECK
      @group_loan_membership.mark_financial_education_attendance( current_user, true , @group_loan)
    elsif params[:action_value].to_i == FALSE_CHECK
      @group_loan_membership.mark_financial_education_attendance( current_user, false , @group_loan)
    end
  end
  
  def execute_final_financial_attendance_marking
    @group_loan_membership  = GroupLoanMembership.find_by_id params[:entity_id]
    @group_loan = @group_loan_membership.group_loan
    
    if params[:action_value].to_i == TRUE_CHECK
      @group_loan_membership.mark_final_financial_education_attendance( current_user, true , @group_loan)
    elsif params[:action_value].to_i == FALSE_CHECK
      @group_loan_membership.mark_final_financial_education_attendance( current_user, false , @group_loan)
    end
  end

=begin
  Marking the LOAN DISBURSEMENT ATTENDANCE
=end

  def execute_loan_disbursement_attendance_marking
    @group_loan_membership  = GroupLoanMembership.find_by_id params[:entity_id]
    @group_loan = @group_loan_membership.group_loan
    
    if params[:action_value].to_i == TRUE_CHECK
      @group_loan_membership.mark_loan_disbursement_attendance( current_user, true , @group_loan) 
    elsif params[:action_value].to_i == FALSE_CHECK
      @group_loan_membership.mark_loan_disbursement_attendance( current_user, false , @group_loan) 
    end
  end
  
  def execute_final_loan_disbursement_attendance_marking
    @group_loan_membership  = GroupLoanMembership.find_by_id params[:entity_id]
    @group_loan = @group_loan_membership.group_loan
    
    if params[:action_value].to_i == TRUE_CHECK
      @group_loan_membership.mark_final_loan_disbursement_attendance( current_user, true , @group_loan)
    elsif params[:action_value].to_i == FALSE_CHECK
      @group_loan_membership.mark_final_loan_disbursement_attendance( current_user, false , @group_loan)
    end
  end

=begin
  For Cashier to disburse group loan 
=end

  def group_loan_disbursement_recipients
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_memberships = @group_loan.group_loan_memberships.order("created_at DESC")
  end
  
end
