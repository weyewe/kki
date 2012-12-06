class MemberAttendance < ActiveRecord::Base
  belongs_to :weekly_task 
  
  # def self.mark_member_attendance_for( member, weekly_task, current_user   )
  #    if weekly_task.is_prev_weekly_task_approved? and 
  #          weekly_task.attendance_marking_not_closed?
  #      MemberAttendance.create(:weekly_task_id => weekly_task.id,
  #                      :member_id => member.id,
  #                      :is_present => true ,
  #                      :attendance_marker_id => current_user.id )
  #    else
  #      return false 
  #    end
  #  end
  
  
  def is_late?
    self.attendance_status == ATTENDANCE_STATUS[:present_late]
  end
  
  def is_on_time?
    self.attendance_status == ATTENDANCE_STATUS[:present_on_time]
  end
  
  def is_notice?
    self.attendance_status == ATTENDANCE_STATUS[:notice]
  end
  
  def is_absent?
    self.attendance_status == ATTENDANCE_STATUS[:absent]
  end
  
  
  def self.all_selectable_attendance_status 
    # ATTENDANCE_STATUS = {
    #   :unmarked => 0 , 
    #   :present_on_time => 1 , 
    #   :present_late => 2 , 
    #   :absent => 3 ,
    #   :notice => 4 
    # } 
    result = [
      ["Hadir" , ATTENDANCE_STATUS[:present_on_time] ],
      [ "Terlambat" , ATTENDANCE_STATUS[:present_late]  ],
      [ "Izin" , ATTENDANCE_STATUS[:notice] ]  ,
      [ "Tidak Hadir" , ATTENDANCE_STATUS[:absent] ]  
    ]
    return result 
  end
end
