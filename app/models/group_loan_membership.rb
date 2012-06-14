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
  
  def update_defaultee_compulsory_savings_deduction
    default_payment = self.default_payment 
    total_compulsory_savings = self.member.saving_book.total_compulsory_savings
    if default_payment.is_defaultee == true 
      glp = self.group_loan_product 
      total_amount = self.unpaid_backlogs.count*( glp.interest + glp.principal)
      if total_amount <= total_compulsory_savings
        default_payment.amount_of_compulsory_savings_deduction = total_amount 
      else
        # will be handled by group
        default_payment.amount_of_compulsory_savings_deduction = total_compulsory_savings 
        default_payment.amount_to_be_shared_with_non_defaultee = total_amount - total_compulsory_savings
      end
      default_payment.save 
    end
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
    if group_loan.is_started == true
      return group_loan_membership  
    end
    
    
    
    if not group_loan_membership.nil?
      return group_loan_membership
    end
    
    
    # special for group_membership_creation
    # a new group membership can't be created if the member has ongoing active group_loan
    if member.current_active_group_loans != 0 
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
      puts "THIS shit is saved"
    else
      puts "NANOOOO THIS SHIT IS NOT SAVED"
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

  protected
  def destroy_group_loan_subcription
    GroupLoanSubcription.find(:all, :conditions => {
      :group_loan_membership_id => self.id
    }).each {|x| x.destroy }
  end
  
  
end
