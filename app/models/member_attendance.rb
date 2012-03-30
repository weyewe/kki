class MemberAttendance < ActiveRecord::Base
  belongs_to :weekly_task 
  
  def self.mark_member_attendance_for( member, weekly_task, current_user   )
    if weekly_task.is_prev_weekly_task_approved? and 
          weekly_task.attendance_marking_not_closed?
      MemberAttendance.create(:weekly_task_id => weekly_task.id,
                      :member_id => member.id,
                      :is_present => true ,
                      :attendance_marker_id => current_user.id )
    else
      return false 
    end
  end
  
  
end
