class WeeklyTasksController < ApplicationController
  
=begin
  Weekly Meeting Code
=end
  def select_weekly_meeting_for_attendance_marking
    setup_for_select_weekly_meeting
  end
  
  def mark_attendance
    setup_for_weekly_task_fulfillment_details
  end
  
  def close_weekly_meeting
    setup_for_weekly_meeting_task_closing
  end
  
=begin
  Weekly Payment Code 
=end

  def select_weekly_meeting_for_weekly_payment
    setup_for_select_weekly_meeting
  end
  
  def make_member_payment
    setup_for_weekly_task_fulfillment_details
  end
  
  def close_weekly_meeting_for_member_payment
    setup_for_weekly_meeting_task_closing
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
    @group_loan_memberships = @group_loan.group_loan_memberships.includes(:member).order("created_at DESC")
  end
  
  def setup_for_weekly_meeting_task_closing
    @weekly_task = WeeklyTask.find_by_id( params[:entity_id])
    @weekly_task.close_weekly_meeting( current_user )
    @group_loan = @weekly_task.group_loan
  end
  
end
