class WeeklyTasksController < ApplicationController
  def select_weekly_meeting_for_attendance_marking
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @weekly_tasks = @group_loan.weekly_tasks.order("week_number ASC")
  end
  
  def mark_attendance
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @weekly_task = WeeklyTask.find_by_id params[:weekly_task_id]
    @group_loan_memberships = @group_loan.group_loan_memberships.includes(:member).order("created_at DESC")
  end
  
  def close_weekly_meeting
    @weekly_task = WeeklyTask.find_by_id( params[:entity_id])
    @weekly_task.close_weekly_meeting( current_user )
    @group_loan = @weekly_task.group_loan
  end
end
