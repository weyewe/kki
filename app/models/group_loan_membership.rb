class GroupLoanMembership < ActiveRecord::Base
  belongs_to :member
  belongs_to :group_loan
  
  belongs_to :sub_group 
  
  
  has_many :weekly_attendances
  has_many :weekly_payments 
  
  has_one :group_loan_subcription
  has_one :group_loan_product, :through => :group_loan_subcription
  
  # in the case of default payment (group loan)
  has_one :default_payment
  
  
  before_destroy :destroy_group_loan_subcription
  
  def update_defaultee_savings_deduction
    default_payment = self.default_payment 
    total_compulsory_savings = self.member.saving_book.total_compulsory_savings
    total_extra_savings = self.member.saving_book.total_extra_savings
    total_deductible_member_savings = total_compulsory_savings + total_extra_savings
    
    # refresh the state 
    default_payment.amount_of_compulsory_savings_deduction = BigDecimal("0")
    default_payment.amount_of_extra_savings_deduction = BigDecimal("0")
    default_payment.amount_to_be_shared_with_non_defaultee = BigDecimal("0")
    
    
    if default_payment.is_defaultee == true 
      
      total_amount = default_payment.unpaid_grace_period_amount
      puts "POST payment, unpaid grace period amount: #{total_amount}"
      
      
      
      # do the deduction 
      if total_amount <= total_compulsory_savings
        puts "glm id #{self.id}, case 1"
        default_payment.amount_of_compulsory_savings_deduction = total_amount 
      elsif total_amount > total_compulsory_savings &&  total_amount <= total_deductible_member_savings 
        puts "glm id #{self.id}, case 2"
        default_payment.amount_of_compulsory_savings_deduction = total_compulsory_savings 
        default_payment.amount_of_extra_savings_deduction = total_amount  - total_compulsory_savings
      elsif total_amount > total_deductible_member_savings 
        # will be handled by group
        puts "glm id #{self.id}, case 3"
        
        
        default_payment.amount_of_compulsory_savings_deduction = total_compulsory_savings 
        default_payment.amount_of_extra_savings_deduction = total_extra_savings
        default_payment.amount_to_be_shared_with_non_defaultee = total_amount - total_deductible_member_savings
      end
    else
    end
    
    
    default_payment.save 
    puts "Total compulsory savings: #{total_compulsory_savings}"
    puts "total extra savings : #{total_extra_savings}"
    puts "compulsory deduction: #{default_payment.amount_of_compulsory_savings_deduction}"
    puts "extra savings deduction: #{default_payment.amount_of_extra_savings_deduction}"
    puts "to be shared: #{default_payment.amount_to_be_shared_with_non_defaultee}"
  end
  
  def create_default_payment_for_the_default_member
    DefaultPayment.create(:group_loan_membership_id => self.id , :is_defaultee => true )
  end
  
  def create_default_payment_for_the_non_default_member
    DefaultPayment.create(:group_loan_membership_id => self.id , :is_defaultee => false )
  end
  
  def unpaid_backlogs
    BacklogPayment.find(:all, :conditions => {
      :group_loan_id => self.group_loan_id,
      :member_id => self.member_id,
      :is_cleared => false 
    })
  end
  
  def total_backlogs
    BacklogPayment.find(:all, :conditions => {
      :group_loan_id => self.group_loan_id,
      :member_id => self.member_id
    })
  end
  
  def has_unpaid_backlogs?
    unpaid_backlogs.count != 0 
  end
  
  def add_deposit(field_worker, amount ) 
    # loan_product = self.group.group_loan 
    # "principal"
    # t.decimal  "interest"
    # t.decimal  "min_savings"
    # t.decimal  "admin_fee"
    # t.decimal  "initial_savings"
    self.initial_deposit = amount 
    self.initial_deposit_creator_id = field_worker.id
    self.paid_initial_deposit = true 
    self.save 
  end
  
  def add_initial_saving( field_worker, amount ) 
    loan_product = self.group.group_loan 
    if amount < loan_product.min_savings
      return false 
    else
      self.inital_saving = amount 
      self.initial_saving_creator_id = field_worker.id
      self.paid_initial_saving = true 
      # add the hook to update the Saving Book
      # create the payment hook here
      self.save 
    end
  end
  
  def add_admin_fee( field_worker, amount )
    loan_product = self.group.group_loan 
    if amount < loan_product.admin_fee
      return false 
    else
      self.paid_admin_fee = true 
      self.admin_fee_creator_id = field_worker.id
      # create the payment hook here
      self.save 
    end
  end
  
  
=begin
  Related with the group_loan_membership creation
=end
  def self.create_membership( creator, member, group_loan)
    if creator.nil? or member.nil? or group_loan.nil?
      puts "Some are nil"
      return nil 
    end
    
    if member.office_id != group_loan.office_id
      puts "Different member office_id"
      return nil
    end
    
    if creator.active_job_attachment.office_id != group_loan.office_id
      puts "creator is not in the same office"
      return nil
    end
    
    
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => member.id,
      :group_loan_id => group_loan.id
    })
    
     # business logic , no new membership can be generated if the group loan is running 
    if group_loan.is_started == true or  group_loan.is_closed == true 
      return group_loan_membership  
    end
    
  
    
    
    
    if not group_loan_membership.nil?
      return group_loan_membership
    end
    
    
    # special for group_membership_creation
    # a new group membership can't be created if the member has ongoing active group_loan
    if member.current_active_group_loans.count != 0 
      return group_loan_membership
    end
    
    group_loan_membership = GroupLoanMembership.create(
      :member_id => member.id,
      :group_loan_id => group_loan.id
    )
    GroupLoanSubcription.create :group_loan_membership_id => group_loan_membership.id 
    # put the user activity list on who the creator is 
    return group_loan_membership
  end
  
  def self.destroy_membership( destroyer, member, group_loan)
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => member.id,
      :group_loan_id => group_loan.id
    })
    
    # business logic , no new membership can be generated if the group loan is running 
    if group_loan.is_started == true 
      return group_loan_membership
    end
    
    if  group_loan_membership.nil?
      return group_loan_membership
    end
    
    
    group_loan_membership.destroy 
    # put the user activity list on who the destroyer is 
  end
  
=begin
  Attendance Marking for group loan: financial education and group loan disbursement
  By loan inspector
=end

  def mark_financial_education_attendance( employee, attendance , group_loan)
    # if that loan inspector has assignment_type :loan_inspector, proceed, else return nil 
    if attendance.nil?  or group_loan.nil? or employee.nil?
      return nil
    end
    
    
    if not group_loan.has_assigned_role?(:field_worker, employee)
      puts "no assignment role"
      return nil
    end
    
    if group_loan.is_started == false
      puts "not started"
      return nil
    end
    
    
    self.financial_lecture_attendance_marker_id = employee.id 
    self.is_attending_financial_lecture = attendance
    if attendance == false 
      self.is_attending_loan_disbursement = false 
      self.final_loan_disbursement_attendance = false
      self.final_loan_disbursement_attendance_marker_id = employee.id  
      self.is_active = false
      self.deactivation_case = GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_lecture_absent]
    end
    self.save 
    if self.save
      # puts "THIS shit is saved"
    else
      # puts "NANOOOO THIS SHIT IS NOT SAVED"
      puts "#{self.errors}"
    end
    return self  
  end
  
  # the loan_inspector version version
  def mark_final_financial_education_attendance( employee, attendance , group_loan)
    # if that loan inspector has assignment_type :loan_inspector, proceed, else return nil 
    if attendance.nil?  or group_loan.nil? or employee.nil?
      return nil
    end
    
    
    if not group_loan.has_assigned_role?(:loan_inspector, employee)
      puts "no assignment role"
      return nil
    end
    
    if group_loan.is_started == false
      puts "not started"
      return nil
    end
    
    
    self.final_financial_lecture_attendance_marker_id = employee.id 
    self.final_financial_lecture_attendance = attendance
    if attendance == false 
      self.is_attending_loan_disbursement = false 
      self.is_active = false
      self.deactivation_case = GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_lecture_absent]
    elsif attendance == true 
      self.is_attending_loan_disbursement = nil 
      self.final_loan_disbursement_attendance = nil
      self.final_loan_disbursement_attendance_marker_id = nil
      
      self.is_active = true
      self.deactivation_case = nil
    end
    self.save 
    return self  
  end
  
  # attendance marking for loan disbursement
  def mark_loan_disbursement_attendance( employee, attendance , group_loan)
    if attendance.nil?  or group_loan.nil? or employee.nil?
      return nil
    end
    
    
    if not group_loan.has_assigned_role?(:field_worker, employee)
      puts "=++++++++++++=====no assignment role"
      return nil
    end
    
    if group_loan.is_started == false
      puts "not started"
      return nil
    end
    
    if self.final_financial_lecture_attendance == false or 
      self.final_financial_lecture_attendance.nil?
      # puts "no financial lecture attendance"
      return nil
    end
    
    if group_loan.is_financial_education_attendance_done == false
      puts "financial education not yet finalized"
      return nil
    end
    
    
    
    self.loan_disbursement_attendance_marker_id = employee.id 
    if attendance == false 
      self.is_active = false 
      self.deactivation_case = GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_disbursement_absent]
    end
    self.is_attending_loan_disbursement = attendance
    self.save 
    return self
  end
  
  def mark_final_loan_disbursement_attendance( employee, attendance , group_loan)
    # if that loan inspector has assignment_type :loan_inspector, proceed, else return nil 
    if attendance.nil?  or group_loan.nil? or employee.nil?
      return nil
    end
    
    
    if not group_loan.has_assigned_role?(:loan_inspector, employee)
      puts "no assignment role"
      return nil
    end
    
    if group_loan.is_started == false
      puts "not started"
      return nil
    end
    
    if self.final_financial_lecture_attendance == false
      return nil
    end
    
    
    self.final_loan_disbursement_attendance_marker_id = employee.id 
    self.final_loan_disbursement_attendance = attendance
    if attendance == false 
      self.is_active = false
      self.deactivation_case = GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_disbursement_absent]
    elsif attendance == true 
      self.is_active = true
      self.deactivation_case = nil
    end
    self.save 
    return self  
  end
  
  
  
=begin
  Declaring that the setup payment will be deducted from Loan Disbursement 
=end

  def declare_setup_payment_by_loan_deduction
    self.deduct_setup_payment_from_loan = true
    self.save 
  end
  
  def min_setup_payment
    group_loan_product = self.group_loan_product
    group_loan_product.admin_fee + group_loan_product.initial_savings 
  end
  
  def has_paid_setup_payment?
    (self.has_paid_setup_fee == true) or
    (self.deduct_setup_payment_from_loan == true )
  end


=begin
  On Closing the GroupLoan  -> port the compulsory savings to the extra savings. They can take it out 
  # how can we test this shit? 
=end
  def migrate_compulsory_savings_to_extra_savings(employee)
    # transactional activity 
    result = TransactionActivity.port_compulsory_savings_to_extra_savings(self, employee)
    if not result.nil?
      self.is_compulsory_savings_migrated = true
      self.save 
    end
  end
  
  def compulsory_savings_to_be_ported_to_extra_savings
    member = self.member
    group_loan = self.group_loan 
    
    
    # all the weekly payment  + backlog payment during weekly payment cycle
    member_transaction_activity_id_list_in_group_loan = TransactionActivity.find(:all, :conditions => {
      :member_id => member.id ,
      :loan_type => LOAN_TYPE[:group_loan] , 
      :loan_id => group_loan.id ,
      :transaction_case => (BASIC_WEEKLY_PAYMENT_START..BASIC_WEEKLY_PAYMENT_END) # TRANSACTION_CASE[]  -> starts with 777
    }).map{|x| x.id }
    
    # initial savings through loan disbursement deduction 
    member_transaction_activity_for_loan_disbursement_deduction_initial_savings = TransactionActivity.find(:all, :conditions => {
      :member_id => member.id ,
      :loan_type => LOAN_TYPE[:group_loan] , 
      :loan_id => group_loan.id ,
      :transaction_case => TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction]
    }).map{|x| x.id }
    
    # compulsory savings during grace period -> no compulsory savings, moron! 
    # member_transaction_activity_id_list_grace_period = TransactionActivity.find(:all, :conditions => {
    #   :member_id => member.id ,
    #   :loan_type => LOAN_TYPE[:group_loan] , 
    #   :loan_id => group_loan.id ,
    #   :transaction_case => (GRACE_PERIOD_PAYMENT_START..GRACE_PERIOD_PAYMENT_END) # TRANSACTION_CASE[]  -> starts with 777
    # }).map{|x| x.id }
    
    # compulsory savings deduction for default payment 
    member_transaction_activity_for_default_payment_resolution = TransactionActivity.find(:all, :conditions => {
      :member_id => member.id ,
      :loan_type => LOAN_TYPE[:group_loan] , 
      :loan_id => group_loan.id ,
      :transaction_case => TRANSACTION_CASE[:default_payment_automatic_deduction]
    }).map{|x| x.id }
    
    
    
    transaction_entries_in_weekly_payment = TransactionEntry.find(:all, :conditions => {
      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_saving], 
      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward], #adding money to the account 
      :transaction_activity_id => member_transaction_activity_id_list_in_group_loan
    })
    
    # no compulsory savings in grace period 
    # transaction_entries_in_grace_period_payment = TransactionEntry.find(:all, :conditions => {
    #    :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_saving], 
    #    :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward], #adding money to the account 
    #    :transaction_activity_id => member_transaction_activity_id_list_grace_period
    #  })
    # puts "~~~~~~~~~~~~~~~~~~~total transaction activity representing weekly payment: #{member_transaction_activity_id_list_in_group_loan.count}\n"*10
    # puts "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^total transaction entries in weekly payment: #{transaction_entries_in_weekly_payment.count}\n"*10
    
    transaction_entries_in_auto_deduct_setup_payment = TransactionEntry.find(:all, :conditions => {
      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:initial_savings], 
      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward],
      :transaction_activity_id => member_transaction_activity_for_loan_disbursement_deduction_initial_savings
    })
    
    transaction_entries_in_auto_deduct_default_payment_resolution = TransactionEntry.find(:all, :conditions => {
      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:default_loan_resolution_compulsory_savings_withdrawal], 
      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward],
      :transaction_activity_id => member_transaction_activity_for_default_payment_resolution
    })
    
    
    
    total_amount = BigDecimal("0")
    
    transaction_entries_in_weekly_payment.each do |te|
      total_amount += te.amount
      # not this simple. remember, that the compulsory_savings is used to pay default payment contribution? 
    end
    
    transaction_entries_in_auto_deduct_setup_payment.each do |te|
      total_amount += te.amount
    end
    
    transaction_entries_in_auto_deduct_default_payment_resolution.each do |te|
      total_amount -+ te.amount 
    end
        # 
        # member.port_compulsory_savings_to_extra_savings( total_amount , group_loan ) 
    return total_amount 
  end



  def weekly_payments_paid_during_active_period
    # number of weekly_payment + number of backlogs_payment paid during active_weekly_payment_period (24 weeks period )
    # => before grace period
    total_weekly_payments = MemberPayment.where(:weekly_task_id => self.group_loan.weekly_task_id_list, 
    :member_id => self.member.id, 
    :has_paid => true,
    :no_payment => false , 
    :only_savings => false
    ).count
    
    total_backlogs_paid_before_grace_period = BacklogPayment.where(:member_id => member.id, 
            :group_loan_id => group_loan.id, 
            :is_cleared => true , 
            :clearance_period => BACKLOG_CLEARANCE_PERIOD[:in_weekly_payment_cycle]
    ).count 
    
    total_payment_before_grace_period =  total_weekly_payments + total_backlogs_paid_before_grace_period
  end
  
=begin
  Grace Period Payment 
=end
  def grace_period_payments
    TransactionActivity.where(:member_id => self.member_id, 
                              :loan_id => self.group_loan_id, 
                              :loan_type => LOAN_TYPE[:group_loan],
                              :transaction_case => (GRACE_PERIOD_PAYMENT_START..GRACE_PERIOD_PAYMENT_END)  )
  end
  
  
  protected
  def destroy_group_loan_subcription
    GroupLoanSubcription.find(:all, :conditions => {
      :group_loan_membership_id => self.id
    }).each {|x| x.destroy }
  end
  
  
end
