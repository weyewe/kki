class WeeklyTask < ActiveRecord::Base
  has_many :member_payments
  has_many :member_attendances 
  belongs_to :group_loan
  
  has_many :backlog_payments
  
  # after_create :create_the_respective_meeting_attendances_and_payment_collections
  
  
  # extract member payment for this group loan at the week number => weekly_task.week_number 
  # not necessarily paid in the same week
  ## it can be paid from the previous week 
  def member_payment_for(member)  
      # MemberPayment.find(:first,:conditions => {
      #   :weekly_task_id => self.id,
      #   :member_id => member.id ,
      #   :week_number => self.week_number
      # })
    MemberPayment.joins(:weekly_task).where( :member_id => member.id, 
      :week_number => self.week_number,
      :weekly_task => {:group_loan_id => self.group_loan_id }   ).order("created_at DESC").first
  end
  
  def total_members_present
    self.member_attendances.where(:attendance_status => ATTENDANCE_STATUS[:present_on_time]).count
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
    # self.member_payments.where( :has_paid => false ,:is_independent_weekly_payment => false).count
    self.member_payments.where{
      (has_paid.eq false ) & 
      (is_independent_weekly_payment.eq false ) & 
      (transaction_activity_id.eq nil )
      
    }.count
  end
  
  def total_independent_payment
    self.member_payments.where(:is_independent_weekly_payment => true, :has_paid => true  ).count 
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
    
    
     # mark_member_attendance( member, current_user,ATTENDANCE_STATUS[:present_late]  )
    no_attendance_member_id_list.each do |member_id|
       # mark_member_attendance( member, current_user,ATTENDANCE_STATUS[:present_late]  )
       
      MemberAttendance.create :weekly_task_id => self.id, 
                  :member_id => member_id, 
                  :attendance_status => ATTENDANCE_STATUS[:absent] ,
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
  
  def close_weekly_payment(current_user)
    
    if self.member_payment_not_closed? and 
              self.member_payment_can_be_closed?
              
      if self.attendace_marking_closed?
        self.is_weekly_payment_collection_finalized = true
        self.weekly_payment_collection_finalizer_id = current_user.id
        self.weekly_payment_collection_done_time = self.create_current_date_time  
        self.save
      else
        return false 
      end
    end
            
              
    
  end
  
  
  def attendance_marking_not_closed?
    self.is_weekly_attendance_marking_done == false 
  end
  
  def attendace_marking_closed?
    not attendance_marking_not_closed?
  end
  
  def attendance_marking_can_be_closed?
    is_prev_weekly_task_approved?
  end
  
  def attendance_marking_can_be_done?
    is_prev_weekly_task_approved?
  end
  
  def member_payment_not_closed?
    self.is_weekly_payment_collection_finalized == false 
  end
  
  def member_payment_closed?
    not member_payment_not_closed?
  end
  
  def member_payment_can_be_closed?
    # all member_payment has been made
    # either : only_savings, basic_payment_and_more, or no_payment
    # self.core_member_weekly_payments.count ==  self.group_loan.active_group_loan_memberships.count 
    # self.member_payments.count == self.group_loan.active_group_loan_memberships.count 
    
    # if all member has paid weekly payment
    self.group_loan.active_group_loan_memberships.each do |glm|
      if not self.has_paid_weekly_payment?(glm.member) 
        return false 
      end
    end
    
    return true 
  end

  
  def member_payment_can_be_started?
    # the previous weekly task is approved by cashier 
    is_prev_weekly_task_approved? # and attendace_marking_closed?
  end
  
  def has_attendance(member)
    member_attendance = self.member_attendances.where(:member_id => member.id ).first
    if member_attendance.nil?
      return false
    elsif [
          ATTENDANCE_STATUS[:present_on_time] , 
          ATTENDANCE_STATUS[:present_late],
          ATTENDANCE_STATUS[:notice],
          ATTENDANCE_STATUS[:absent]
        ].include?(member_attendance.attendance_status )
      return true 
    end
  end
  
  def member_attendance(member)
    self.member_attendances.where(:member_id => member.id ).first 
  end
  
  
  
  def mark_attendance_as_late(member, current_user )
    mark_member_attendance( member, current_user,ATTENDANCE_STATUS[:present_late]  )
  end
  
  def mark_attendance_as_present(member, current_user )
    mark_member_attendance( member, current_user,ATTENDANCE_STATUS[:present_on_time]  )
  end
  
  def mark_attendance_as_absent( member, current_user )
    mark_member_attendance( member, current_user,ATTENDANCE_STATUS[:absent]  )
  end
  
  def mark_attendance_as_notice( member, current_user )
    mark_member_attendance( member, current_user,ATTENDANCE_STATUS[:notice]  )
  end
  
  def mark_member_attendance( member , current_user, attendance_status)
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
              :attendance_status => attendance_status ,
              :member_id => member.id 
            )
      else
        member_attendance.attendance_status = attendance_status
        member_attendance.save 
      end
      
      return member_attendance 
    else
      return false
    end
  end
  
=begin
  Creating weekly payment 
=end

  def group_independent_payment_transactions
    active_member_id_list = self.group_loan.active_group_loan_memberships.map{|x| x.member_id }
    transaction_id_list = self.member_payments.
                              where{( member_id.in active_member_id_list) & 
                                    ( is_independent_weekly_payment ==  true ) & 
                                    ( transaction_activity_id.not_eq nil )}.
                              map{|x| x.transaction_activity_id }
    
    TransactionActivity.where(:id => transaction_id_list, :is_deleted => false, :is_canceled => false )
  end
  
 

  def group_payment_transactions
    active_member_id_list = self.group_loan.active_group_loan_memberships.map{|x| x.member_id }
    transaction_id_list = self.member_payments.
                              where{( member_id.in active_member_id_list) & 
                                    ( is_independent_weekly_payment ==  false )  &
                                    ( transaction_activity_id.not_eq nil ) }.
                              map{|x| x.transaction_activity_id }
    
    TransactionActivity.where(:id => transaction_id_list, :is_deleted => false , :is_canceled => false )
  end

  # get all transactions for member that is happening on that weekly task 
  def transactions_for_member(member)
    weekly_task = self 
    transaction_id_list = self.member_payments.
                              where{( member_id.eq member.id ) & 
                                    ( is_independent_weekly_payment.eq false ) & 
                                    ( transaction_activity_id.not_eq nil )}.
                              map{|x| x.transaction_activity_id }
    
    TransactionActivity.where(:id => transaction_id_list, :is_deleted => false, :is_canceled => false  )
  end
  
  def valid_transaction_activity?( transaction_activity )
    active_transaction_activity_id_list=  self.transactions_for_member(transaction_activity.member.id ).map{|x| x.id }
    
    
    active_transaction_activity_id_list.include?( transaction_activity.id )
  end


  def WeeklyTask.valid_duration?( group_loan_membership, number_of_weeks, number_of_backlogs)
    group_loan = group_loan_membership.group_loan
    member  = group_loan_membership.member 
    return false if (number_of_weeks < 0) or (number_of_backlogs < 0 ) 
    return false if (number_of_weeks == 0 ) and (number_of_backlogs == 0)
    return false if ( group_loan.remaining_weekly_tasks_count_for_member(member) < number_of_weeks )  or 
                    (number_of_weeks > group_loan.total_weeks)
    return false if group_loan_membership.unpaid_backlogs.count < number_of_backlogs
    
    return true 
  end
  
  
  def WeeklyTask.valid_weekly_task_payment?(weekly_task, 
                              group_loan_membership, 
                              number_of_weeks, 
                              number_of_backlogs)
                              
    # group_loan = group_loan_membership.group_loan
    # member  = group_loan_membership.member 
    # return false if (number_of_weeks < 0) or (number_of_backlogs < 0 ) 
    # 
    # return false if (number_of_weeks == 0 ) and (number_of_backlogs == 0)
    #  
    # return false if ( group_loan.remaining_weekly_tasks_count_for_member(member) < number_of_weeks )  or 
    #                 (number_of_weeks > group_loan.total_weeks)
    # 
    # return false if group_loan.unpaid_backlogs.count < number_of_backlogs
    
    return false if not WeeklyTask.valid_duration?( group_loan_membership, number_of_weeks, number_of_backlogs)
    
    return false if not weekly_task.can_create_payment?
    
    return true 
  end
  
  def can_create_payment?
    # if the prev week payment has been approved by the cashier
    # and the current payment has not been approved by the cashier & not finalized yet
    if self.week_number > 1 
      prev_weekly_task = self.previous_weekly_task 
      if (  self.is_weekly_payment_approved_by_cashier == false and 
            self.is_weekly_payment_collection_finalized == false ) and 
         (  prev_weekly_task.is_weekly_payment_approved_by_cashier == true and 
            prev_weekly_task.is_weekly_payment_collection_finalized == true  )
          return true
      end
    elsif self.week_number == 1
      if (  self.is_weekly_payment_approved_by_cashier == false and 
            self.is_weekly_payment_collection_finalized == false )
          return true
      end
    end
    
    return false 
  end
  
  def previous_weekly_task
    if self.week_number == 1 
      return self
    end
    
    WeeklyTask.where(:week_number => self.week_number - 1, :group_loan_id => self.group_loan_id ).first
  end

  
  def create_weekly_payment_declared_as_only_savings(member, transaction_activity, cash_passed)
    if self.has_paid_weekly_payment?(member)  
      return nil
    else 
      member_payment = self.member_payments.create(
        :transaction_activity_id => transaction_activity.id,
        :member_id => member.id , 
        :has_paid => true,
        :no_payment => false ,
        :only_savings => true ,
        :cash_passed => cash_passed,
        :week_number => self.week_number 
      )
      
      
      group_loan = self.group_loan 
      BacklogPayment.create(
        :group_loan_id => group_loan.id, 
        :weekly_task_id => self.id , 
        :member_payment_id => member_payment.id, 
        :backlog_type => BACKLOG_TYPE[:only_savings_without_weekly_payment],
        :member_id => member.id 
      )
      
      return member_payment 
      # self.add_total_cash( amount )
    end
  end
  
  def is_last_weekly_task?
    if self.week_number == self.group_loan.total_weeks 
      return self
    end
  end
  
  def next_weekly_task
    total_weeks = self.group_loan.total_weeks
    
    
    WeeklyTask.find(:first, :conditions => {
      :group_loan_id => self.group_loan_id,
      :week_number => self.week_number + 1 
    })
  end
  
  
  # not backlog... if not paid, will be promoted to backlog
  def WeeklyTask.first_unpaid_weekly_task(group_loan, member)
    paid_week_number_list = MemberPayment.find(:all, :conditions => {
      :weekly_task_id => group_loan.weekly_tasks.map {|x| x.id } , 
      :member_id => member.id 
    }).map {|x| x.weekly_task.week_number }
    
    last_paid_week_number = paid_week_number_list.sort.last # by default, sort is ascending
    if last_paid_week_number.nil?
      last_paid_week_number  = 0 
    end
    if last_paid_week_number != group_loan.total_weeks
      return group_loan.weekly_tasks.where(:week_number => last_paid_week_number + 1 ).first 
    else
      return nil
    end
    
  end
  
  
  def create_backlog_payment( member, transaction_activity, cash_passed, is_independent_payment)
    self.member_payments.create(
      :transaction_activity_id => transaction_activity.id,
      :member_id => member.id , 
      :cash_passed => cash_passed,
      :week_number => nil ,
      :is_independent_weekly_payment => is_independent_payment
    )
  end
  
  def create_extra_savings_only_payment( member, transaction_activity, cash_passed)
     self.member_payments.create(
       :transaction_activity_id => transaction_activity.id,
       :member_id => member.id , 
       :has_paid => true ,
       :only_extra_savings => true,
       :cash_passed => cash_passed,
       :week_number =>nil
     )
  end
  
  def create_extra_savings_only_independent_payment( member, transaction_activity, cash_passed)
     self.member_payments.create(
       :transaction_activity_id => transaction_activity.id,
       :member_id => member.id , 
       :has_paid => true ,
       :only_extra_savings => true,
       :cash_passed => cash_passed,
       :week_number =>nil,
       :is_independent_weekly_payment => true 
     )
  end
  
  

=begin
  IN-GROUP WEEKLY PAYMENT 
=end
  def create_basic_weekly_payment( member, transaction_activity, cash_passed, is_independent_payment)

    week_number = self.week_number 
    while MemberPayment.has_made_payment_for( self, week_number, member ) do
      week_number += 1 
    end
    self.member_payments.create(
      :transaction_activity_id => transaction_activity.id,
      :member_id => member.id , 
      :has_paid => true ,
      :no_payment => false, 
      :only_savings => false,
      :cash_passed => cash_passed,
      :week_number =>  week_number ,
      :is_independent_weekly_payment => is_independent_payment
    )
  end
  
  def first_unpaid_week_number_for_member( member) 
    weekly_task = self
    week_number_list = MemberPayment.where{
                          (weekly_task_id.eq weekly_task.id ) & 
                          (week_number.not_eq nil)}.map{|x| x.week_number }
    week_number_list.max + 1 
  end
  
  def create_multiple_weeks_payment( member, transaction_activity, number_of_weeks, cash_passed, is_independent_payment)
    
    current_week = self.week_number
  
  
    if self.has_paid_weekly_payment?(member)
      current_week = self.first_unpaid_week_number_for_member( member) 
    end
    
    
    final_week = current_week + number_of_weeks - 1 
    group_loan = self.group_loan
    
    if final_week > self.group_loan.weekly_tasks.count 
      return nil
    end
    
    (current_week..final_week).each do |week_number|
      if week_number == current_week 
        self.member_payments.create(
          :transaction_activity_id => transaction_activity.id,
          :cash_passed => cash_passed, 
          :has_paid => true ,
          :week_number => week_number ,
          :member_id => member.id ,
          :is_independent_weekly_payment => is_independent_payment
        )
      else
        self.member_payments.create(
          :transaction_activity_id => transaction_activity.id,
          :cash_passed => BigDecimal("0"), 
          :has_paid => false,
          :week_number => week_number,
          :member_id => member.id,
          :is_independent_weekly_payment => is_independent_payment
        )
      end
    end
  end
  
  def create_weekly_payment_declared_as_no_payment(employee, member)
    
    if self.has_paid_weekly_payment?(member)  
      return nil
    else 
      member_payment = self.member_payments.create(
        :transaction_activity_id => nil,
        :member_id => member.id , 
        :has_paid => false,
        :no_payment => true ,
        :only_savings => false ,
        :week_number => self.week_number
      )
      
      
      group_loan = self.group_loan 
      BacklogPayment.create(
        :group_loan_id => group_loan.id, 
        :weekly_task_id => self.id , 
        :member_payment_id => member_payment.id, 
        :backlog_type => BACKLOG_TYPE[:no_payment],
        :member_id => member.id 
      )
      
      MemberPaymentHistory.create_weekly_payment_history_entry(
        employee,  # creator 
        self,  # period object 
        self.group_loan,  # the loan product
        LOAN_PRODUCT[:group_loan],
        member, # the member who paid 
        BigDecimal('0'),  #  the cash passed
        BigDecimal('0'), # savings withdrawal used
        0, # in grace payment, number of weeks is nil 
        0, # in grace payment, number of weeks is nil 
        nil, # the transaction  
        REVISION_CODE[:original_no_payment],
        PAYMENT_PHASE[:weekly_payment] 
      )
      
      return member_payment 
    end
  end
  
  # only handle from (normal, only savings) => no weekly payment 
  def update_weekly_payment_declared_as_no_payment(employee, member)
    member_payment =  self.member_payment_for(member)
    
    
    # if it is not approved by cashier yet 
    return nil if  not self.can_create_payment?
     
    
    if member_payment.no_payment?   
      return nil
    else 
      
      revision_code = nil 
      if member_payment.is_full_payment?
        revision_code   = REVISION_CODE[:normal][:no_payment] 
      elsif  member_payment.only_savings_payment?
        revision_code   = REVISION_CODE[:only_savings][:no_payment] 
        
      end
      
      current_transaction = self.transactions_for_member(member).order("created_at DESC").first 
      current_transaction = TransactionActivity.find_by_id( member_payment.transaction_activity_id )
      return nil if current_transaction.nil? 
      
      current_transaction.revert_transaction_effect(member_payment) 
      
      current_transaction.revert_member_payment_effect( member_payment )
      current_transaction.is_deleted = true 
      current_transaction.save
      
      member.reload
      member_payment = self.member_payments.create(
        :transaction_activity_id => nil,
        :member_id => member.id , 
        :has_paid => false,
        :no_payment => true ,
        :only_savings => false ,
        :week_number => self.week_number
      )
      
      
      group_loan = self.group_loan 
      BacklogPayment.create(
        :group_loan_id => group_loan.id, 
        :weekly_task_id => self.id , 
        :member_payment_id => member_payment.id, 
        :backlog_type => BACKLOG_TYPE[:no_payment],
        :member_id => member.id 
      ) 
      
      
      MemberPaymentHistory.create_weekly_payment_history_entry(
        employee,  # creator 
        self,  # period object 
        self.group_loan,  # the loan product
        LOAN_PRODUCT[:group_loan],
        member, # the member who paid 
        BigDecimal('0'),  #  the cash passed
        BigDecimal('0'), # savings withdrawal used
        0, # in grace payment, number of weeks is nil 
        0, # in grace payment, number of weeks is nil 
        nil, # the transaction  
        revision_code ,
        PAYMENT_PHASE[:weekly_payment] 
      )
    end
    
    return member_payment  
  end
  
  
  
=begin
  Checking weekly payment 
=end
# only savings IS  counted as weekly payment 
  def has_paid_weekly_payment?(member) 
    MemberPayment.joins(:weekly_task).
                where(:week_number => self.week_number, :member_id => member.id, 
                      :weekly_task => {:group_loan_id => self.group_loan_id}  ).length != 0   
  end
  
  
  
  def weekly_payment_declared_as_no_payment?(member)
    member_payment = self.member_payments.where(:member_id => member.id).first 
    ( member_payment.no_payment == true ) and (member_payment.has_paid == false) and
     (member_payment.only_savings == false) and (member_payment.transaction_activity_id.nil?)
  end
  
  def weekly_payment_declared_as_only_savings?(member)
    member_payment = self.member_payments.where(:member_id => member.id).first 
    ( member_payment.no_payment == false ) and (member_payment.has_paid == true) and
     (member_payment.only_savings == true) and (not member_payment.transaction_activity_id.nil?)
  end
  
  def weekly_payment_declared_as_paid?(member)
    member_payment = self.member_payments.where(:member_id => member.id).first 
    ( member_payment.no_payment == false ) and (member_payment.has_paid == true) and
     (member_payment.only_savings == false) and (not member_payment.transaction_activity_id.nil?)
  end
  
=begin
  For the weekly payment FINALIZATION
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
  
=begin
  For Cashier Approval in the weekly payment collection
=end
  def WeeklyTask.get_pending_cashier_approval_for_weekly_collection( office )
    weekly_tasks_pending_approval = []
    office.running_group_loans.each do |running_group_loan|
      weekly_tasks_pending_approval += running_group_loan.weekly_tasks_pending_cashier_approval
    end
    
    return weekly_tasks_pending_approval
  end
  
  def total_cash_received
    self.member_payments.sum("cash_passed")
  end


  
  
 

  def last_week?
    self.week_number == self.group_loan.total_weeks 
  end

  def approve_weekly_payment_collection( current_user )
    if not current_user.has_role?(:cashier , current_user.active_job_attachment)
      puts "no cashier role"
      return nil 
    end
    
    puts "has been approvd by cashier"
    return nil if self.is_weekly_payment_approved_by_cashier == true 
    
    independent_payments = self.group_independent_payment_transactions.where(:is_approved => false)
    if independent_payments.count != 0 
      return nil
    end
    
    
    self.is_weekly_payment_approved_by_cashier = true 
    self.weekly_payment_approver_id = current_user.id
    self.save
    
    self.group_payment_transactions.each do |transaction_activity|
      transaction_activity.approve_payment(current_user)
    end
    
    if self.last_week?
      group_loan = self.group_loan
      group_loan.is_grace_period = true
      group_loan.save
      
      begin
        ActiveRecord::Base.transaction do
          group_loan.calculate_default_payment_in_grace_period #only principal and interest
        end
      rescue ActiveRecord::ActiveRecordError  
      else
      end
      # group_loan.calculate_default_payment_in_grace_period #only principal and interest
    end
  end
  
  def reject_weekly_payment_collection( current_user )
    self.is_weekly_payment_approved_by_cashier = false 
    self.is_weekly_payment_collection_finalized = false
    self.save
    # send email notification to the field_worker. record in user activity 
  end
  
  def weekly_collection_approved?
    self.is_weekly_payment_approved_by_cashier == true 
  end

  protected
  

  
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
 
end
