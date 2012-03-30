class MemberAttendancesController < ApplicationController
  def create
    @weekly_task  = WeeklyTask.find_by_id params[:weekly_task_id]
    @member = Member.find_by_id params[:entity_id]
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id, 
      :group_loan_id => @weekly_task.group_loan.id 
    })
    @weekly_task.mark_attendance_as_present( @member, current_user )
  end
end
