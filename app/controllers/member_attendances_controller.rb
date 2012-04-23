class MemberAttendancesController < ApplicationController
  def create
    @weekly_task  = WeeklyTask.find_by_id params[:weekly_task_id]
    @member = Member.find_by_id params[:entity_id]
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id, 
      :group_loan_id => @weekly_task.group_loan.id 
    })
    if params[:action_value].to_i == TRUE_CHECK
      @weekly_task.mark_attendance_as_present( @member, current_user )
    elsif params[:action_value].to_i == FALSE_CHECK
      @weekly_task.mark_attendance_as_late( @member, current_user )
    end
  end
end
