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
    elsif params[:action_value].to_i == SPECIAL_NOTICE_CHECK
      @weekly_task.mark_attendance_as_notice( @member, current_user )
    end
  end
  
  def edit_member_attendance
    @weekly_task = WeeklyTask.find_by_id params[:weekly_task_id]
    @member = Member.find_by_id params[:member_id]
    @member_attendance =  MemberAttendance.find(:first, :conditions => { 
      :member_id => @member.id,
      :weekly_task_id => @weekly_task.id
    })
  end
  
  def update_member_attendance
    @weekly_task = WeeklyTask.find_by_id params[:weekly_task_id] 
    @member = Member.find_by_id params[:member_id]
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => @weekly_task.group_loan_id,
      :member_id => @member.id 
    })
    
    @member_attendance =  MemberAttendance.find(:first, :conditions => { 
      :member_id => @member.id,
      :weekly_task_id => @weekly_task.id
    })
    
    if params[:member_attendance][:attendance_status].to_i == ATTENDANCE_STATUS[:present_on_time] 
      @member_attendance.attendance_status = ATTENDANCE_STATUS[:present_on_time] 
    elsif params[:member_attendance][:attendance_status].to_i == ATTENDANCE_STATUS[:present_late] 
      @member_attendance.attendance_status = ATTENDANCE_STATUS[:present_late] 
    elsif params[:member_attendance][:attendance_status].to_i  == ATTENDANCE_STATUS[:notice]  
      @member_attendance.attendance_status = ATTENDANCE_STATUS[:notice] 
    elsif params[:member_attendance][:attendance_status].to_i  == ATTENDANCE_STATUS[:absent]  
      @member_attendance.attendance_status = ATTENDANCE_STATUS[:absent] 
    end 
    @member_attendance.save 
  end
end
