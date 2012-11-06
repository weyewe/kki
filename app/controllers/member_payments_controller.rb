class MemberPaymentsController < ApplicationController
  def create_basic_payment
    @weekly_task  = WeeklyTask.find_by_id params[:weekly_task_id]
    @member = Member.find_by_id params[:entity_id]
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id, 
      :group_loan_id => @weekly_task.group_loan.id 
    })
    @weekly_task.create_basic_payment( @member, current_user )
  end
  
  
  def make_independent_payment
    @office = current_user.active_job_attachment.office
    @group_loan_membership = GroupLoanMembership.find_by_id params[:group_loan_membership_id]
    @group_loan = @group_loan_membership.group_loan 
    @member = @group_loan_membership.member 
    @group_loan_product = @group_loan_membership.group_loan_product
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_independent_weekly_payment_url'
    set_breadcrumb_for @group_loan, 'select_member_for_independent_weekly_payment_url' + "(#{@group_loan.id})", 
                "Select Member"
    set_breadcrumb_for @group_loan, 'make_independent_payment_url' + "(#{@group_loan_membership.id})", 
                "#{t 'process.create_payment'}"
  end
  
  def edit_independent_payment
    @office = current_user.active_job_attachment.office
    @group_loan_membership = GroupLoanMembership.find_by_id params[:group_loan_membership_id]
    @group_loan = @group_loan_membership.group_loan 
    @member = @group_loan_membership.member 
    @group_loan_product = @group_loan_membership.group_loan_product
    
    @transaction_activity = @group_loan_membership.unapproved_independent_payment
    @member_payment = MemberPayment.where(:transaction_activity_id => @transaction_activity.id ).first 
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_independent_weekly_payment_url'
    set_breadcrumb_for @group_loan, 'select_member_for_independent_weekly_payment_url' + "(#{@group_loan.id})", 
                "Select Member"
    set_breadcrumb_for @group_loan, 'edit_independent_payment_url' + "(#{@group_loan_membership.id})", 
                "Edit #{t 'process.create_payment'}"
  end
  
=begin
  INDEPENDENT PAYMENT APPROVAL 
=end
  
  def list_of_independent_payment
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @pending_approval_weekly_task = @group_loan.currently_pending_approval_weekly_task
    @independent_payments = @pending_approval_weekly_task.group_independent_payment_transactions.order("created_at DESC")
    @pending_approval_count  = @pending_approval_weekly_task.group_independent_payment_transactions.where(:is_approved => false).count
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_approve_independent_payment_url'
    set_breadcrumb_for @group_loan, 'list_of_independent_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.approve_independent_payment'}"
                
  end
end
