class WeeklyTasksController < ApplicationController
  
=begin
  Weekly Meeting Code
=end
  def select_weekly_meeting_for_attendance_marking
    setup_for_select_weekly_meeting
    
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_meeting_attendance_marking_path'
    set_breadcrumb_for @group_loan, 'select_weekly_meeting_for_attendance_marking_path' + "(#{@group_loan.id})", 
                "#{t 'process.select_week'}"
    
  end
  
  def mark_attendance
    setup_for_weekly_task_fulfillment_details
    # @group_loan_memberships = @group_loan.active_group_loan_memberships
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_meeting_attendance_marking_path'
    set_breadcrumb_for @group_loan, 'select_weekly_meeting_for_attendance_marking_path' + "(#{@group_loan.id})", 
                "#{t 'process.select_week'}"
    set_breadcrumb_for @group_loan, 'mark_attendance_path' + "(#{@group_loan.id}, #{@weekly_task.id})", 
                "#{t 'process.mark_attendance'}"        
  end
  
  def close_weekly_meeting
    setup_for_weekly_meeting_task_closing
    @weekly_task.close_weekly_meeting( current_user )
  end
  
=begin
  Weekly Payment Code 
=end

  def select_weekly_meeting_for_weekly_payment
    setup_for_select_weekly_meeting
    
    # select_weekly_meeting_for_weekly_payment_url(group_loan)
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_payment_path'
    set_breadcrumb_for @group_loan, 'select_weekly_meeting_for_weekly_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.select_week'}"
  end
  
  def make_member_payment
    setup_for_weekly_task_fulfillment_details
    # @group_loan_memberships = @group_loan.active_group_loan_memberships
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_payment_path'
    set_breadcrumb_for @group_loan, 'select_weekly_meeting_for_weekly_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.select_week'}"
    set_breadcrumb_for @group_loan, 'make_member_payment_url' + "(#{@group_loan.id}, #{@weekly_task.id})", 
                "#{t 'process.make_payment'}"
  end
  
  def close_weekly_payment 
    setup_for_weekly_meeting_task_closing
    @weekly_task.close_weekly_payment( current_user )
  end
  
  

=begin
  Weekly Special Payment 
=end
# deprecated
  def special_weekly_payment_for_member
    
    setup_for_weekly_task_fulfillment_details
    @member = Member.find_by_id params[:member_id]
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id , 
      :group_loan_id => @group_loan.id
    })
    @weekly_task = WeeklyTask.find_by_id params[:weekly_task_id]
    @group_loan_product = @group_loan_membership.group_loan_product
    
    # @transaction_activity = @group_loan_membership.unapproved_independent_payment
    #    
    #    @actual_extra_savings = @member.saving_book.total_extra_savings -
    #                          @transaction_activity.independent_payment_extra_savings_amount + 
    #                          @transaction_activity.savings_withdrawal_amount 
    #                          
    #    @backlog_paid =  @transaction_activity.number_of_backlogs_paid_in_weekly_cycle  
    #    @week_paid  = @transaction_activity.number_of_weeks_paid 
    #    
    #    @actual_payable_backlogs = @group_loan_membership.unpaid_backlogs.count + @backlog_paid
    #    @actual_payable_weeks = @group_loan.remaining_weekly_tasks_count_for_member(@member)  + @week_paid
    #    
    #    @member_payment = MemberPayment.where(:transaction_activity_id => @transaction_activity.id ).first
    
    
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_payment_path'
    set_breadcrumb_for @group_loan, 'select_weekly_meeting_for_weekly_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.select_week'}"
    set_breadcrumb_for @group_loan, 'make_member_payment_url' + "(#{@group_loan.id}, #{@weekly_task.id})", 
                "#{t 'process.make_payment'}"
    set_breadcrumb_for @group_loan, 'special_weekly_payment_for_member_url' + "(#{@group_loan.id}, #{@weekly_task.id}, #{@member.id})", 
                "#{t 'process.special_payment'}"
  end
  
  def edit_transaction_for_member
    
    setup_for_weekly_task_fulfillment_details
    @member = Member.find_by_id params[:member_id]
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id , 
      :group_loan_id => @group_loan.id
    })
    @weekly_task = WeeklyTask.find_by_id params[:weekly_task_id]
    
    @group_loan_product = @group_loan_membership.group_loan_product
    
    @member_payment =  @weekly_task.member_payment_for(@member)
    
    
    @transaction_activity = @group_loan_membership.unapproved_group_weekly_payment
    
    @actual_extra_savings = @member.saving_book.total_extra_savings -
                          @transaction_activity.extra_savings_addition_amount + 
                          @transaction_activity.savings_withdrawal_amount 
                          
    @backlog_paid =  @transaction_activity.number_of_backlogs_paid_in_weekly_cycle  
    @week_paid  = @transaction_activity.number_of_weeks_paid 
    
    @actual_payable_backlogs = @group_loan_membership.unpaid_backlogs.count + @backlog_paid
    @actual_payable_weeks = @group_loan.remaining_weekly_tasks_count_for_member(@member)  + @week_paid
    
    @member_payment = MemberPayment.where(:transaction_activity_id => @transaction_activity.id ).first
    
        # 
        # @transaction_activity = nil 
        # if not @member_payment.no_payment?
        #   @transaction_activity = TransactionActivity.find_by_id  @member_payment.transaction_activity_id
        # end
        # 
    
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_payment_path'
    set_breadcrumb_for @group_loan, 'select_weekly_meeting_for_weekly_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.select_week'}"
    set_breadcrumb_for @group_loan, 'make_member_payment_url' + "(#{@group_loan.id}, #{@weekly_task.id})", 
                "#{t 'process.make_payment'}"
    set_breadcrumb_for @group_loan, 'edit_transaction_for_member_url' + "(#{@group_loan.id}, #{@weekly_task.id}, #{@member.id})", 
                "#{t 'process.edit_payment'}"
  end
  
=begin
  Cashier Approval 
=end
  def list_pending_weekly_collection_approval
    @office = current_user.active_job_attachment.office
    @pending_weekly_tasks_cashier_approval = WeeklyTask.get_pending_cashier_approval_for_weekly_collection(@office)
    add_breadcrumb "#{t 'process.weekly_payment_pending_approval'}", 'list_pending_weekly_collection_approval_url'
  end
  
  def details_weekly_collection
    @weekly_task = WeeklyTask.find_by_id params[:weekly_task_id]
    @group_loan = @weekly_task.group_loan
    @office = current_user.active_job_attachment.office
    # @transaction_activities = []
    # @weekly_task.member_payments.where{ ( cash_passed.not_eq nil)  & 
    #                    ( is_independent_weekly_payment.eq false) 
    #                    }.
    #                 order("created_at ASC").each do |x|     
    #                    if not x.transaction_activity.nil?
    #                      @transaction_activities << x.transaction_activity
    #                    end
    #                 end
    @transaction_activities  = @weekly_task.group_payment_transactions.order("member_id DESC")
    
    
    add_breadcrumb "#{t 'process.weekly_payment_pending_approval'}", 'list_pending_weekly_collection_approval_url'
    set_breadcrumb_for @weekly_task, 'details_weekly_collection_url' + "(#{@weekly_task.id})", 
     "#{t 'process.collection_details'}"
                        
  end
  
  def execute_weekly_collection_approval
    @weekly_task = WeeklyTask.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    if @action_role == APPROVER_ROLE
      if @action_value == TRUE_CHECK
        @weekly_task.approve_weekly_payment_collection( current_user )
      elsif @action_value == FALSE_CHECK
        @weekly_task.reject_weekly_payment_collection( current_user )
      end
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
  
  protected
  def setup_for_select_weekly_meeting
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @weekly_tasks = @group_loan.weekly_tasks.order("week_number ASC")
  end
  
  def setup_for_weekly_task_fulfillment_details
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @weekly_task = WeeklyTask.find_by_id params[:weekly_task_id]
    @group_loan_memberships = @group_loan.active_group_loan_memberships.order("sub_group_id ASC, sub_group_update_datetime ASC").includes(:member)
  end
  
  def setup_for_weekly_meeting_task_closing
    @weekly_task = WeeklyTask.find_by_id( params[:entity_id])
    @group_loan = @weekly_task.group_loan
  end
  
end
