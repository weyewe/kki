class WeeklyTask < ActiveRecord::Base
  has_many :member_payments
  has_many :member_attendances 
  belongs_to :group_loan
  
  
  # after_create :create_the_respective_meeting_attendances_and_payment_collections
  
  
  def total_members_present
    self.member_attendances.where(:is_present => true).count
  end
  
  def total_members_paid
  # thanks to squeel
    self.member_payments.where( :has_paid => true , :only_savings => false ).count
  end
  
  def total_members_paid_only_savings
  # thanks to squeel
    self.member_payments.where( :has_paid => true , :only_savings => true ).count
  end
  
  
  def total_members_not_paying
  # thanks to squeel
    self.member_payments.where( :has_paid => false ).count
  end
  
=begin
  FOr the weekly meeting
=end
  def mark_all_non_existant_member_attendance_as_false(current_user) 
    group_loan = self.group_loan
    group_loan_member_id_list = group_loan.group_loan_memberships.select(:member_id).map do |x|
      x.member_id
    end
    
    marked_group_loan_member_id_list = self.member_attendances.select(:member_id).map do |x|
      x.member_id 
    end
    
    no_attendance_member_id_list = group_loan_member_id_list - marked_group_loan_member_id_list
    
    no_attendance_member_id_list.each do |member_id|
      MemberAttendance.create :weekly_task_id => self.id, 
                  :member_id => member_id, 
                  :is_present => false ,
                  :attendance_marker_id => current_user.id 
    end
    
  end
  
  
  def close_weekly_meeting(current_user)
    if self.is_prev_weekly_task_approved?  #and self.meeting_does_happened
      self.is_weekly_attendance_marking_done = true
      self.attendance_closer_id = current_user.id
      self.weekly_attendance_marking_done_time = self.create_current_date_time  
      self.save
      
      self.mark_all_non_existant_member_attendance_as_false( current_user )
      
      #  create member_attendance for the rest of group_membership, mark them as false 
    else
      return false
    end
  end
  
  def attendance_marking_not_closed?
    self.is_weekly_attendance_marking_done == false 
  end
  
  def has_attendance(member)
    member_attendance = self.member_attendances.where(:member_id => member.id ).first
    if member_attendance.nil?
      return false
    elsif member_attendance.is_present == true 
      return true 
    end
  end
  
  def mark_attendance_as_present( member, current_user)
    if self.attendance_marking_not_closed? and 
        not self.has_attendance(member)
        
      #  if the branch manager re-open the case
      member_attendance = MemberAttendance.find(:first, :conditions => {
        :attendance_marker_id => current_user.id ,
        :member_id => member.id,
        :weekly_task_id => self.id
      })
      
      if member_attendance.nil?
        # if there has not been any member_attendance
        member_attendance =     self.member_attendances.create(   
              :attendance_marker_id => current_user.id ,
              :is_present => true ,
              :member_id => member.id 
            )
      else
        member_attendance.is_present = true
        member_attendance.save 
      end
      
      return member_attendance 
    else
      return false
    end
  end
  
  # gonna make payment 
 
  def create_basic_weekly_payment( member, transaction_activity)
    self.member_payments.create(
      :transaction_activity_id => transaction_activity.id,
      :member_id => member.id , 
      :has_paid => true 
    )
  end
  
  def create_multiple_weeks_payment( member, transaction_activity, number_of_weeks)
    current_week = self.week_number
    final_week = current_week + number_of_weeks - 1 
    group_loan = self.group_loan
    (current_week..final_week).each do |target_week_number|
      group_loan.find_weekly_task_by_week_number( target_week_number ).member_payments.create(
        :transaction_activity_id => transaction_activity.id,
        :member_id => member.id , 
        :has_paid => true
      ) 
    end
  end
  
  # def has_paid_basic_weekly_payment?(member)
  #    self.member_payments.where(:member_id => member.id).length != 0 
  #  end
  
  def has_paid_weekly_payment?(member)
    self.member_payments.where(:member_id => member.id).length != 0 
  end
  
=begin
  For the weekly payment 
=end

  def finalize_weekly_payment(current_user)
    if self.is_prev_weekly_task_approved?
      self.is_weekly_payment_collection_finalized = true
      self.weekly_payment_collection_finalizer_id = current_user.id
      self.weekly_payment_collection_done_time = self.create_current_date_time # UTC time , hey it is datetime. how? 
      #DateTime.new(Time.now.,2,3,4,5,6)
      self.save
    else
      return false
    end
  end
  
  
  def is_prev_weekly_task_approved?
    if self.week_number == 1
      return true
    end
    
    self.prev_weekly_task.is_weekly_payment_approved_by_cashier == true 
  end
  
  def prev_weekly_task
    if self.week_number == 1 
      return self
    end
    
    
    group_loan = self.group_loan
    group_loan.weekly_tasks.find(:first, :conditions => {
      :week_number => self.week_number - 1 
    })
  end
  
  
  protected
  
  # def create_the_respective_meeting_attendances_and_payment_collections
  #    self.create_member_attendances
  #    self.create_member_payments
  #  end
  
  def create_current_date_time
    current_time = Time.now
    datetime = DateTime.new(
      current_time.year,
      current_time.month,
      current_time.day,
      current_time.hour,
      current_time.min,
      current_time.sec
    )
    # UTC TIME ( server time )
    return datetime
  end
  
  # def meeting_does_happened
  #    self.member_attendances.count != 0
  #  end
end
