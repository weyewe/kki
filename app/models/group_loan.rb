=begin
  Group Loan Product, the domain of the branch manager
  Only branchmanager that can create a loan product 
=end
class GroupLoan < ActiveRecord::Base
  has_many :group_loan_memberships
  has_many :members, :through => :group_loan_memberships
  
  has_many :sub_groups
  
  has_many :weekly_tasks
  has_many :backlog_payments 
  
  # belongs_to :group_loan 
  belongs_to :office
  validates_presence_of :name
  
  attr_protected :is_proposed, :group_loan_proposer_id,
                  :is_started, :group_loan_starter_id ,
                  :is_closed, :group_loan_closer_id, 
                  :is_setup_fee_collection_finalized, :setup_fee_collection_finalizer_id, # finalized by loan_officer
                  :is_setup_fee_collection_approved, :setup_fee_collection_approver_id, # approval by cashier
                   :loan_disburser_id,
                  :aggregated_principal_amount, :aggregated_interest_amount,
                  :total_default, :default_creator_id ,
                  :group_leader_id
                  
                  
  has_many :group_loans, :through => :group_loan_assignments
  has_many :group_loan_assignments
                  
                  
=begin
  Referencing User 
=end

  def creator
    User.find_by_id(self.creator_id)
  end
  
  
  
  def self.create_group_loan_with_creator( group_loan_params, creator)
    if not creator.has_role?( :branch_manager , creator.get_active_job_attachment)
      return nil
    end
    
    new_group_loan = GroupLoan.new group_loan_params
    new_group_loan.creator_id = creator.id 
    new_group_loan.office_id = creator.get_active_job_attachment.office.id 
    
    
    if new_group_loan.save
      return new_group_loan
    else
      return nil
    end
  end
  
  def get_commune
    commune = Commune.find_by_id self.commune_id
    village = commune.village
    subdistrict = village.subdistrict
    "#{subdistrict.name}, #{village.name} -- RW #{commune.number }"
  end
  
  # def propose_to_start_group_loan
  #     
  #   end
  #   
  #   def start_loan
  #     ###### IMPORTANT ########## 
  #     # a member can only be in 1 group loan at a given time. 
  #     # so, when the loan is started, destroy all other group loan membership 
  #     # and group loan can't be started if there is a member with no group_loan_subcription 
  #     
  #     ## after the deposit  + initial savings has been received, loan $$$ can be disbursed 
  #   end
  
  def commune
    Commune.find_by_id self.commune_id
  end
  
  def all_group_loan_products_used
    group_loan_product_id_array = GroupLoanSubcription.
                select(:group_loan_product_id).
                where(:group_loan_membership_id => 
                      self.group_loan_membership_ids).map do |group_loan_subcription|
                        group_loan_subcription.group_loan_product_id
                      end
    
    group_loan_product_id_array.uniq.map do |group_loan_product_id|
      GroupLoanProduct.find_by_id group_loan_product_id
    end
  end
  
  def group_loan_membership_ids
    GroupLoanMembership.select(:id).find(:all, :conditions => {
      :group_loan_id => self.id
    }).map {|x| x.id }
  end
  
  def get_membership_for_member( member )
    GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => self.id,
      :member_id => member.id 
    })
  end
  
  def unassigned_members
    # get the group_loan_membership where group_loan_subcription is nil
    # Client.joins(:orders).where(:orders => {:created_at => time_range})
    self.group_loan_memberships.includes(:group_loan_subcription).where(
      :group_loan_subcription => {:group_loan_product_id => nil}
    )
    
  end
  
  def assigned_members_count
    self.group_loan_memberships.count - self.unassigned_members.count 
  end
  
  def paid_members_count
    self.group_loan_memberships.where(
      :has_paid_setup_fee => true
    ).count
  end
  
  def change_group_loan_subcription( new_group_loan_product_id , old_group_loan_product_id)
    new_group_loan_product = GroupLoanProduct.find_by_id  new_group_loan_product_id
    old_group_loan_product = GroupLoanProduct.find_by_id old_group_loan_product_id
    
    
    if not old_group_loan_product.nil?
      delta_principal = new_group_loan_product.loan_amount  - old_group_loan_product.loan_amount
      delta_interest = new_group_loan_product.interest_amount  - old_group_loan_product.interest_amount
    else
      delta_principal = new_group_loan_product.loan_amount 
      delta_interest = new_group_loan_product.interest_amount 
    end
  
    update_aggregated_interest_amount( delta_interest )
    update_aggregated_principal_amount( delta_principal )
  end
  
  def add_group_loan_subcription( group_loan_product_id )
    group_loan_product = GroupLoanProduct.find_by_id  group_loan_product_id
    
    update_aggregated_interest_amount( group_loan_product.interest_amount )
    update_aggregated_principal_amount( group_loan_product.loan_amount )
  end
  
  def update_aggregated_interest_amount( delta_interest) 
    self.aggregated_interest_amount += delta_interest
    self.save
  end
  
  def update_aggregated_principal_amount( delta_principal) 
    self.aggregated_principal_amount += delta_principal
    self.save
  end
  
  def aggregated_interest_rate
    self.aggregated_interest_amount/self.aggregated_principal_amount
  end
  
  def aggregated_interest_rate_percentage
    (self.aggregated_interest_amount/self.aggregated_principal_amount).to_f * 100
  end
  
=begin
  Finalization Approval 
=end

  def equal_loan_duration
    array = self.all_group_loan_products_used.compact.map {|x| x.total_weeks}
    array.uniq.length == 1 
  end

  def has_assigned_field_worker_and_loan_inspector?
    field_worker_assignment_count =  GroupLoanAssignment.get_field_workers_for(self).count
    loan_inspector_assignment_count = GroupLoanAssignment.get_loan_inspectors_for(self).count 
    
    field_worker_assignment_count > 0   && loan_inspector_assignment_count > 0
  end

  def execute_propose_finalization( current_user )
    if self.unassigned_members.count != 0  or self.equal_loan_duration == false  or 
       not  self.has_assigned_field_worker_and_loan_inspector?
      return nil
    else
      self.is_proposed = true 
      self.group_loan_proposer_id = current_user.id 
      self.save 
      return self 
    end
  end
  
  def is_rejected?
    self.is_proposed == false && self.is_started == false 
  end
    
  def start_group_loan( current_user )
   
    if not current_user.has_role?(:branch_manager, current_user.active_job_attachment )
      return nil
    end
    
    if not self.is_proposed == true
      return nil
    end
    
    if all_members_have_equal_loan_duration?
      self.is_started = true 
      self.group_loan_starter_id = current_user.id 
      self.total_weeks = self.total_loan_duration
      self.save
    else
      return nil
    end
    
    
    # delete the group loan  membership from other group loan 
 
    
    # preventing declaring setup payment by loan deduction 
    if self.is_setup_fee_collection_finalized  == true && 
      self.is_setup_fee_collection_approved  == true 
      return
    end
    
    # BUSINESS LOGIC: all loan's setup fee are deducted from the loan disbursement 
    self.group_loan_memberships.each do |glm|
      glm.declare_setup_payment_by_loan_deduction
      glm.member.destroy_non_started_group_loan_memberships(glm.group_loan)
    end
    self.is_setup_fee_collection_finalized  = true 
    self.is_setup_fee_collection_approved  = true 
    self.save
  end
  
  def all_members_have_equal_loan_duration?
    group_loan_product_duration = [] 
    self.group_loan_memberships.each do |x|
      group_loan_product_duration << x.group_loan_product.total_weeks 
    end
    
    if group_loan_product_duration.uniq.length == 1 
      return true
    else
      return false
    end
  end
  
  def reject_group_loan_proposal( current_user )
    self.is_proposed = false
    self.is_started = false  
    # even though it is rejected, we need to know who did that 
    self.group_loan_starter_id = current_user.id 
    self.save
    
    # maybe, in the operational_activity timeline, it is gonna be much better. Tracability
  end
  
=begin
  Financial Education and Group Loan Disbursement Attendance
=end

  def destroy_assignment( assignment_symbol, user ) 
    if self.is_started == true 
      return nil
    end
    
    GroupLoanAssignment.find(:all, :conditions => {
      :group_loan_id => self.id,
      :assignment_type =>  GROUP_LOAN_ASSIGNMENT[assignment_symbol],
      :user_id => user.id
    }).each do |gla|
      gla.destroy 
    end
    
    return true # success in destroying 
  end
  
# adding the employee responsible
  def add_assignment(assignment_symbol, user)
    past_assignments = GroupLoanAssignment.find(:all, :conditions => {
      :group_loan_id => self.id,
      :assignment_type =>  GROUP_LOAN_ASSIGNMENT[assignment_symbol],
      :user_id => user.id 
    })
    
    if past_assignments.count > 0 
      puts "The past assignment value is #{past_assignments.count}"
      puts "The user email is :#{user.email}  "
      puts "past_assignments.first.inspect: #{past_assignments.first.inspect}"
      return nil
    else
      puts "we are gonna create the new one"
      return GroupLoanAssignment.create(
        :group_loan_id => self.id,
        :assignment_type =>  GROUP_LOAN_ASSIGNMENT[assignment_symbol],
        :user_id => user.id
      )
    end
  end
  
  def has_assigned_role?(assignment_symbol, user)
    past_assignments = GroupLoanAssignment.find(:all, :conditions => {
      :group_loan_id => self.id,
      :assignment_type =>  GROUP_LOAN_ASSIGNMENT[assignment_symbol],
      :user_id => user.id 
    })
    
    if past_assignments.count > 0 
      return true
    else
      return false 
    end
    
  end
  
  def loan_inspectors
    GroupLoanAssignment.find(:all,:conditions => {
      :group_loan_id => self.id, 
      :assignment_type => GROUP_LOAN_ASSIGNMENT[:loan_inspector]
    })
  end
  
  def field_workers
    GroupLoanAssignment.find(:all,:conditions => {
      :group_loan_id => self.id, 
      :assignment_type => GROUP_LOAN_ASSIGNMENT[:field_worker]
    })
  end

=begin
  Get member who are presents for financial education, loan disbursement and both
=end

  # present in both of the financial education and loan disbursement
  def active_group_loan_memberships
    self.group_loan_memberships.where(:is_active => true )
  end
  
  def preserved_active_group_loan_memberships
    active_group_loan_memberships  + self.group_loan_memberships.where(:is_active => false , 
    :deactivation_case => GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed])
  end
  
  def non_active_group_loan_memberships
    self.group_loan_memberships.where(:is_active => false  )
  end
  
  def membership_attending_financial_education
    self.group_loan_memberships.where(:final_financial_lecture_attendance => true)
  end
  
  def membership_to_receive_loan_disbursement
    self.membership_attending_financial_education
  end
  
  def membership_reported_receiving_loan_disbursement
    self.group_loan_memberships.where(:has_received_loan_disbursement => true )
  end
  
  def membership_attending_financial_education_and_loan_disbursement
    self.group_loan_memberships.where(:final_financial_lecture_attendance => true, :final_loan_disbursement_attendance => true )
  end
  
  
  def legitimate_membership_not_receiving_loan_disbursement
    self.membership_attending_financial_education_and_loan_disbursement - self.membership_reported_receiving_loan_disbursement
  end
  
  def membership_whose_loan_disbursement_must_be_returned_to_cashier
    self.membership_to_receive_loan_disbursement - self.membership_reported_receiving_loan_disbursement
  end
  
  
  
=begin
  Finalize financial education attendance_summary 
=end

  def marked_group_loan_memberships_attendance_for_financial_education
    self.group_loan_memberships.where(:is_attending_financial_lecture => [true, false] )
  end
  
  # ,
  #   :deactivation_case => [nil,GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_disbursement_absent]]
  def marked_group_loan_memberships_attendance_for_loan_disbursement
    self.group_loan_memberships.where(:is_attending_financial_lecture => [true, false] , 
      :is_attending_loan_disbursement => [true,false])
  end
  
  def group_loan_memberships_attendance_display_for_loan_disbursement
    self.group_loan_memberships.where(:is_attending_financial_lecture => [true, false] , 
      :is_attending_loan_disbursement => [nil, true,false],
      :deactivation_case => [nil,GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_disbursement_absent]] )
  end
  
  def propose_financial_education_attendance_finalization(employee)
    if employee.nil? or not self.has_assigned_role?(:field_worker, employee) 
      puts "--------in the group loan, no assigned role"
      return nil
    end
    
    if self.marked_group_loan_memberships_attendance_for_financial_education.count == self.group_loan_memberships.count 
      self.financial_education_finalization_proposed = true 
      self.financial_education_finalization_proposer_id = employee.id 
      self.save
    else
      return nil
    end
  end
  
  def finalize_financial_attendance_summary(employee)
    if employee.nil? or not self.has_assigned_role?(:loan_inspector, employee) 
      puts "--------in the group loan, no assigned role"
      return nil
    end
    
    
    
    if self.financial_education_finalization_proposed == true 
      puts "HEHEHE, with proposal"
      self.group_loan_memberships.each do |glm|
        if glm.final_financial_lecture_attendance.nil?
          puts "#{glm.id} is_attending_financial_lecture: #{glm.is_attending_financial_lecture}"
          glm.final_financial_lecture_attendance = glm.is_attending_financial_lecture
          glm.final_financial_lecture_attendance_marker_id = employee.id 
          glm.save
        end
      end
      
      self.is_financial_education_attendance_done = true 
      self.financial_education_inspector_id = employee.id 
      self.save 
    else
      puts "SHITE, no proposal "
      return nil
    end
  end
  
  def propose_loan_disbursement_attendance_finalization(employee)
    if employee.nil? or not self.has_assigned_role?(:field_worker, employee) 
      puts "--------in the group loan, no assigned role"
      return nil
    end
    
    if self.is_financial_education_attendance_done == false
      return nil
    end
    
    if self.marked_group_loan_memberships_attendance_for_loan_disbursement.count == self.group_loan_memberships.count 
      self.loan_disbursement_finalization_proposed = true 
      self.loan_disbursement_finalization_proposer_id = employee.id 
      self.save
    else
      return nil
    end
  end
  
  
  def finalize_loan_disbursement_attendance_summary(employee)
    if employee.nil? or not self.has_assigned_role?(:loan_inspector, employee) 
      puts "--------in the group loan, no assigned role"
      return nil
    end
    
    if self.is_loan_disbursement_attendance_done
      return nil
    end
    
    if  self.loan_disbursement_finalization_proposed == true 
      self.group_loan_memberships.each do |glm|
        if glm.final_loan_disbursement_attendance.nil?
          glm.final_loan_disbursement_attendance = glm.is_attending_loan_disbursement
          glm.save
        end
      end
      
      
      self.is_loan_disbursement_attendance_done = true 
      self.loan_disbursement_inspector_id = employee.id
      self.save
      return self
      
    else
      return nil
    end
    
      
  end
    
    

=begin
  Passing the cash to field worker 
=end

  def total_amount_passed_to_field_worker
    # it is assumed that the setup fee is deducted from loan disbursement 
    total_amount_passed = BigDecimal("0")
    self.membership_to_receive_loan_disbursement.each do |glm|
      glp = glm.group_loan_product  
      total_amount_passed += glp.loan_amount - glp.setup_payment_amount
    end
    
    return total_amount_passed
  end
  
  def total_amount_to_be_returned_to_cashier
    total_amount = BigDecimal("0")
    puts "~~~~~~~~~~ the count is #{self.membership_whose_loan_disbursement_must_be_returned_to_cashier.count}"
    # membership_whose_loan_disbursement_must_be_returned_to_cashier
    self.membership_whose_loan_disbursement_must_be_returned_to_cashier.each do |glm|
      glp = glm.group_loan_product 
      total_amount += glp.loan_amount - glp.setup_payment_amount
    end
    
    return total_amount 
  end
  
  
=begin
  finalize setup fee collection 
=end
  def total_deposit
    self.group_loan_memberships.sum("deposit")
  end
  
  def total_initial_savings
    self.group_loan_memberships.sum("initial_savings")
  end
  
  def total_admin_fee
    self.group_loan_memberships.sum("admin_fee")
  end
  
  
  
  def uncollected_setup_fee
    self.group_loan_memberships.where{
      (has_paid_setup_fee.eq false ) & 
      (deduct_setup_payment_from_loan.eq false ) 
    }
  end
  
  def execute_finalize_setup_fee_collection( current_user )
     if self.uncollected_setup_fee.count != 0 
       return nil
     else
       self.is_setup_fee_collection_finalized  = true 
       self.setup_fee_collection_finalizer_id = current_user.id 
       self.save
     end 
  end
  

=begin
  For Cashier
=end
  def approve_setup_fee_collection( current_user )
    self.is_setup_fee_collection_approved  = true 
    self.setup_fee_collection_approver_id  = current_user.id 
    self.save
    
    # create all those payment payable : loan disbursement 
  end
  
  def reject_setup_fee_collection( current_user )
    self.is_setup_fee_collection_finalized = false 
    self.save 
  end
  
  def is_setup_fee_collection_rejected?
    self.is_setup_fee_collection_approved == false 
  end
  
  # Loan Disbursement 
  def disbursed_members
    self.group_loan_memberships.where(:has_received_loan_disbursement => true, :is_active => true  )
  end
  
  def undisbursed_members
    self.group_loan_memberships.where(:has_received_loan_disbursement => false , :is_active => true )
  end
  
  def total_disbursement_amount
    value = BigDecimal.new('0')
    self.group_loan_memberships.each {|x|  value += x.group_loan_product.loan_amount }
    
    return value
  end
  
  def total_withdrawn_amount
    value = BigDecimal("0")
    self.group_loan_memberships.where(:is_attending_financial_lecture => true).each do |glm|
      value += glm.group_loan_product.loan_amount_deducted_by_setup_amount
    end
    
    return value 
  end
  
  def total_returned_cash_from_loan_disbursement
    value = BigDecimal("0")
    if self.is_loan_disbursement_attendance_done == false
      return value
    else
    
    
    withdrawn_amount = self.total_withdrawn_amount 
    
    self.active_group_loan_memberships.each do |glm|
      withdrawn_amount -= glm.group_loan_product.loan_amount_deducted_by_setup_amount
    end
    return withdrawn_amount 
    
    # self.group_loan_memberships.where(:is)
    end
  end
  
  
  
  # create default_payment object for each active glm 
  def create_default_payments
    self.active_group_loan_memberships.each do |glm|
      # positive thinking, assuming that every active member is non defaultee
      glm.create_default_payment_for_the_non_default_member 
    end
  end
  
  def execute_finalize_loan_disbursement( current_user )
    
    if not current_user.has_role?(:cashier, current_user.active_job_attachment)
      return nil
    end
    
    if self.undisbursed_members.count != 0 
      return false
    else
      self.is_loan_disbursement_approved = true 
      self.loan_disbursement_approver_id = current_user.id
      self.save 
      
      
      self.initiate_weekly_tasks
      self.create_default_payments 
      # group loan has these things
      # create the weekly_payment
        # weekly_payment has_many member_payments
      # create the weekly meeting 
        # weekly meeting has many member_attendances 
        
      return true 
    end
  end
  
  def total_loan_duration
    self.group_loan_memberships.first.group_loan_product.total_weeks
  end
  
  def total_completed_meeting
    self.weekly_tasks.where(:is_weekly_attendance_marking_done => true ).count
  end
  
  def total_completed_group_payment
    self.weekly_tasks.where(:is_weekly_payment_collection_finalized => true ).count
  end
  
  def initiate_weekly_tasks
    total_weeks = self.total_weeks
    (1..total_weeks).each do |week_number|
      WeeklyTask.create :week_number => week_number, :group_loan_id => self.id 
    end
  end
  
  
  def find_weekly_task_by_week_number( week_number )
    WeeklyTask.find(:first, :conditions => {
      :week_number => week_number,
      :group_loan_id => self.id 
    })
  end
  
  def currently_executed_weekly_task
    # the first available, in which it is still a virgin , 
    # where its attendance must be marked before going for the payment 
    self.weekly_tasks.find(:first, :conditions => {
      :is_weekly_attendance_marking_done  => false ,
      :is_weekly_payment_collection_finalized => false,
      :is_weekly_payment_approved_by_cashier =>  false
    }, :limit => 1, :order => "week_number ASC")
  end
  
  
  def currently_being_payment_collected_weekly_task
    # attendance marking has been finalized 
    # now is in the $$ collection 
    self.weekly_tasks.find(:first, :conditions => {
      :is_weekly_attendance_marking_done  => true ,
      :is_weekly_payment_collection_finalized => false,
      :is_weekly_payment_approved_by_cashier =>  false
    }, :limit => 1, :order => "week_number ASC")
  end
  
=begin
  For weekly task approval by cashier 
=end
  def weekly_tasks_pending_cashier_approval
    self.weekly_tasks.where(
     :is_weekly_attendance_marking_done  => true ,
     :is_weekly_payment_collection_finalized => true,
     :is_weekly_payment_approved_by_cashier =>  false
    )
  end
  
=begin
  For backlog
=end
  def total_backlogs
    self.backlog_payments.count
  end
  
  def total_resolved_backlogs
    self.backlog_payments.where(:is_cleared => true ).count
  end
  
=begin
  Group Loan Management
=end

  def group_leader
    if self.group_leader_id.nil?
      return nil
    else
      Member.find_by_id( self.group_leader_id )
    end
  end
  
  
  def set_group_leader( member)
    self.group_leader_id = member.id
    self.save 
  end
  
  def remove_group_leader
    self.group_leader_id = nil
    self.save
  end
  
  
  def unassigned_members_to_sub_group
    self.group_loan_memberships.where(:sub_group_id => nil )
  end
 
=begin
  Declare default group loan... hahahaha, complicated bitch 
=end
  def completed_weekly_tasks
    self.weekly_tasks.where(
            :is_weekly_attendance_marking_done => true ,
            :is_weekly_payment_collection_finalized => true, 
            :is_weekly_payment_approved_by_cashier => true 
    )
  end
  
  
  def weekly_task_id_list
    self.weekly_tasks.collect do |weekly_task|
      weekly_task.id
    end
  end
  
  
  def accounted_weekly_payments_by(member)
    MemberPayment.find(:all,:conditions => {
      :member_id => member.id, 
      :weekly_task_id => self.weekly_task_id_list
    }).map{|x| x.weekly_task}
  end
  
  def remaining_weekly_tasks_count_for_member(member)
    number_of_accounted_weeks = self.accounted_weekly_payments_by(member).count
    remaining_weeks_count = self.weekly_tasks.count - number_of_accounted_weeks
  end
  
  # def total_remaining_weekly_tasks
  #     self.total_weeks - self.completed_weekly_tasks.count
  #   end
  
  # def declare_default( current_user )
  #   if not current_user.has_role?(:branch_manager, current_user.get_active_job_attachment)
  #     return nil
  #   end
  #   
  #   if self.completed_weekly_tasks.count != self.total_weeks
  #     return nil
  #   end
  #   
  #   # put this in transaction block
  #   self.default_creator_id = current_user.id
  #   self.is_group_loan_default = true 
  #   self.save 
  #   
  #   
  #   self.generate_default_payments(current_user)
  #   
  # end
  
  
  # def extract_total_default_amount
  #   total_default = BigDecimal("0")
  #   
  #   self.unpaid_backlogs.each do |backlog|
  #     total_default += backlog.amount
  #   end
  #   
  #   self.total_default_amount  =  total_default
  #   self.save 
  #   
  #   return total_default
  # end
    # 
    # def extract_total_default_amount
    #   
    #   total_default = BigDecimal("0")
    #   
    #   self.sub_groups.each do |sub_group|
    #     total_sub_group_default = sub_group.extract_total_unpaid_backlogs
    #     puts "Total default sub_group #{sub_group.number}: #{sub_group.extract_total_unpaid_backlogs}"
    #     
    #     total_default += total_sub_group_default
    #   end
    #   
    #   self.total_default_amount  =  total_default
    #   self.save 
    #   return total_default
    # end
    # 
  # def declare_backlog_payments_as_default
  #   self.unpaid_backlogs.each do |backlog|
  #     backlog.is_group_loan_declared_as_default = true
  #     backlog.save
  #   end
  # end
  
  
=begin
  GRACE PERIOD PAYMENT
=end
  def unpaid_backlogs
    self.backlog_payments.where(:is_cleared => false )
  end
  
  def unpaid_backlogs_grace_period_amount
    total_amount = BigDecimal("0")
    
    self.unpaid_backlogs.each do |backlog|
      member = backlog.member
      glm = self.get_membership_for_member( member )
      group_loan_product = glm.group_loan_product
      total_amount += group_loan_product.grace_period_weekly_payment
    end
 
    return total_amount 
  end
  
=begin
  GRACE PERIOD APPROVAL
=end
  def pending_approval_grace_period_transactions
    transaction_activity_id_list = []
    BacklogPayment.where(:clearance_period => BACKLOG_CLEARANCE_PERIOD[:in_grace_period], 
      :is_cashier_approved => false,
      :group_loan_id => self.id,
      :is_cleared => true  ).each do |backlog|
      
      transaction_activity_id_list << backlog.transaction_activity_id_for_backlog_clearance
    end
    transaction_activity_id_list
    transaction_activity_id_list.uniq! 

    TransactionActivity.where(:id => transaction_activity_id_list)
  end
  
  def grace_period_transactions
    transaction_activity_id_list = []
    BacklogPayment.where(:clearance_period => BACKLOG_CLEARANCE_PERIOD[:in_grace_period], 
      :is_cashier_approved => [false,true],
      :group_loan_id => self.id,
      :is_cleared => true  ).each do |backlog|
      
      transaction_activity_id_list << backlog.transaction_activity_id_for_backlog_clearance
    end
    transaction_activity_id_list
    transaction_activity_id_list.uniq! 

    TransactionActivity.where(:id => transaction_activity_id_list)
    
  end
  
  def pending_approval_grace_period_transactions_amount
    total_amount = BigDecimal("0")
    self.pending_approval_grace_period_transactions.each do |ta|
      total_amount += ta.total_transaction_amount
    end
    
    return total_amount
  end
  
  
  
  def pending_approval_backlogs
    self.backlog_payments.where(:is_cleared => true , :is_cashier_approved => false)
  end
  
  # def total_defaultee
  #    extract_default_member_id.count
  #  end
  #  
  # def extract_default_member_id
  #   list_of_default_member_id = BacklogPayment.list_member_id_with_default_in_group_loan( self ) 
  # end
  # 
  # def total_default_member
  #   self.extract_default_member_id.length 
  # end
  
  # def members_paid_default_payment
  #   list_of_non_defaultee_member_id = self.extract_non_default_member_id 
  #   
  #   non_defaultee_glm_id=  GroupLoanMembership.find(:all, :conditions => {
  #       :member_id => list_of_non_defaultee_member_id,
  #       :group_loan_id => self.id 
  #     }).map{|x| x.id }
  #     
  #   DefaultPayment.where(
  #     :group_loan_membership_id => non_defaultee_glm_id,
  #     :is_paid => true 
  #   )
  # end
  # 
  # def default_payments
  #   list_of_non_defaultee_member_id = self.extract_non_default_member_id 
  #   
  #   non_defaultee_glm_id=  GroupLoanMembership.find(:all, :conditions => {
  #       :member_id => list_of_non_defaultee_member_id,
  #       :group_loan_id => self.id 
  #     }).map{|x| x.id }
  #     
  #   DefaultPayment.where(
  #     :group_loan_membership_id => non_defaultee_glm_id,
  #     :is_defaultee => false 
  #   )
  # end
  # 
  # 
  # def pending_approval_default_payments
  #   members_paid_default_payment.where(:is_cashier_approved => false)
  # end
  
  # def total_paid_default_payment
  #   members_paid_default_payment.sum("amount_paid")
  # end
  # 
  def total_default_payment_paid_by_office
    members_paid_default_payment.sum("amount_assumed_by_office")
  end
  
  # def total_members_paid_default_payment
  #   self.members_paid_default_payment.count
  # end
  
  
  def extract_non_default_member_id
    list_of_default_member_id = self.extract_default_member_id
    all_member_id = []
    self.active_group_loan_memberships.each do |glm|
      all_member_id << glm.member_id
    end
    
    all_member_id - list_of_default_member_id
  end
  
  def group_loan_membership_id_list 
    self.group_loan_memberships.collect{|x| x.id }
  end
  
  
  
  def generate_default_payments_per_group_loan_membership
    total_default = self.total_default_amount
    
    list_of_non_default_member_id = self.extract_non_default_member_id
    
    
    # self.group_loan_memberships.each do |glm|
    #   puts "@@@ current glm.member_id = #{glm.member_id}"
    #   if list_of_non_default_member_id.include?(glm.member_id)
    #     glm.create_default_payment_for_the_non_default_member
    #     # DefaultPayment.create :group_loan_membership_id => glm.id , :is_defaultee => false # by default 
    #   else
    #     # DefaultPayment.create :group_loan_membership_id => glm.id , :is_defaultee => true 
    #     glm.create_default_payment_for_the_default_member
    #   end
    # end
    
    self.group_loan_memberships.each do |glm|
      DefaultPayment.create :group_loan_membership_id => glm.id
    end
    
    
    
    # get all member without default 
    
    
    
    if list_of_non_default_member_id.length == 0 
      # set the default payment for group share and sub group share == 0 
      # by default 
      return nil 
    else
      
      group_share_amount =  ( total_default* 0.5 ) / list_of_non_default_member_id.length 


      list_of_non_default_member_id.each do |non_default_member_id|
        glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => non_default_member_id,
          :group_loan_id => self.id 
        })
        default_payment = glm.default_payment
        default_payment.set_amount_group_share( group_share_amount ) 
      end

      self.sub_groups.each do |sub_group|
        sub_group.generate_default_payments( list_of_non_default_member_id )
        sub_group.round_up_total_default_payment
      end


      # we want the sum of total sub_group_share + group_share default payment, so that we will know the 
      # amount absorbed by kki  << important

      # group_loan_membership_id_list = self.extract_group_loan_membership_id_list
      # total_amount_subgroup_share = DefaultPayment.find(:all, :conditions => {
      #         :group_loan_membership_id => self.group_loan_membership_id_list
      #       }).sum("amount_subgroup_share")
      # 
      #       total_amount_group_share = DefaultPayment.find(:all, :conditions => {
      #         :group_loan_membership_id => self.group_loan_membership_id_list
      #       }).sum("amount_group_share")
      # 
      #       total_amount_absorbed_by_office = total_default - total_amount_subgroup_share - total_amount_group_share
      #       self.total_calculated_default_absorbed_by_office= total_amount_absorbed_by_office
      #       self.save
      
      
    end
  end
  
  
  def auto_deduct_default_payments_from_savings(current_user)
    self.group_loan_memberships.includes(:default_payment).each do |glm|
      default_payment = glm.default_payment
      TransactionActivity.execute_default_payment_deduction_from_savings(self,default_payment,glm, current_user)
    end
    
  end
  
  def close_group_loan(current_user)
    
    if self.is_closed == true 
      return nil
    end
    # prevent double submission? 
    
    if not current_user.has_role?(:branch_manager, current_user.active_job_attachment)
      return nil
    end
    
    if self.unpaid_backlogs.count > 0 and self.is_default_payment_resolution_approved == false 
      return nil
    elsif ( self.unpaid_backlogs.count > 0 and self.is_default_payment_resolution_approved == true   ) or
          ( self.unpaid_backlogs.count == 0 )
      
      self.active_group_loan_memberships.each do |glm|
        if glm.is_compulsory_savings_migrated == false 
          glm.migrate_compulsory_savings_to_extra_savings(current_user) # find all transactions associated with this group loan
          glm.is_active = false
          glm.deactivation_case =  GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed]
          glm.save
        end
        # move it over  -> from compulsory to extra 
      end
      
      
      self.is_closed = true 
      self.group_loan_closer_id = current_user.id
      self.save
    end
  end
  
  
  def finalized_weekly_tasks
    self.weekly_tasks.where(:is_weekly_payment_approved_by_cashier => true ) 
  end
  
  def has_finalized_all_weekly_tasks?
    self.finalized_weekly_tasks.count == self.total_weeks 
  end
  
  def generate_default_payments(current_user)
    
    if not current_user.has_role?(:branch_manager, current_user.active_job_attachment) 
      return nil
    end
    
    if not self.has_finalized_all_weekly_tasks?
      return nil
    end
    
    self.extract_total_default_amount
    # by now, we know the default amount for each subgroup
    # total default amount for the group == sum of default amount from all subgroups
   
    self.generate_default_payments_per_group_loan_membership  # sub_group_share and group_share
    self.declare_backlog_payments_as_default #but not cleared. that is the basis for future data
    
    self.auto_deduct_default_payments_from_savings(current_user)
    # self.close_group_loan(current_user)
  end
  
  
  def deduct_defaultee_compulsory_savings(employee)
    if not employee.has_role?(:branch_manager, employee.active_job_attachment ) 
      return nil 
    end
    
    @group_loan.group_loan_defaultees.each do |default_glm|
      TransactionActivity.create_default_payment_savings_deduction( default_glm, employee )
    end
    
    # we will have arrays of default payment, containing the amount deducted, default payment type == defaultee_savings_deduction
    
  end
  
  
  # def legitimate_custom_default_payment_input?(  non_defaultee_and_payment_amount_pair )
  #   total_contribution = BigDecimal("0")
  #   
  #   list_of_non_defaultee_id = self.list_of_non_defaultee_id 
  #   input_list_of_non_defaultee_id = [] 
  #   amount_to_be_deducted_list = []
  #   zero_value = BigDecimal("0")
  #   
  #   # no negative value 
  #   non_defaultee_and_payment_amount_pair.each do |key,value|
  #     input_list_of_non_defaultee_id << key 
  #     
  #     parsed_value = BigDecimal(value.to_s)
  #     if parsed_value < zero_value 
  #       return false
  #     end
  #     amount_to_be_deducted_list << parsed_value 
  #   end
  #   
  #   # encompassing all non defaultee 
  #   if (input_list_of_non_defaultee_id - list_of_non_defaultee_id).length != 0  or 
  #       (list_of_non_defaultee_id - input_list_of_non_defaultee_id).length != 0  
  #     return false
  #   end
  #   
  #   
  #   
  #   non_defaultee_and_payment_amount_pair.each do |key,value|
  #     parsed_value = BigDecimal(value.to_s)
  #     total_contribution += parsed_value 
  #   end
  #   
  #   if total_contribution < self.default_payment_to_be_shared_among_non_defaultee
  #     return false
  #   end
  # end
  # 
  # def execute_custom_default_payment_for_non_defaultee( non_defaultee_and_payment_amount_pair, employee )
  #   if not employee.has_role?(:branch_manager, employee.active_job_attachment) 
  #     return nil 
  #   end
  #   
  #   total_contribution = BigDecimal("0")
  #   if self.legitimate_custom_default_payment_input?(  non_defaultee_and_payment_amount_pair ) == true 
  #     non_defaultee_and_payment_amount_pair.each do |key,value|
  #       non_defaultee_glm = GroupLoanMembership.find_by_id( key ) 
  #       payment_amount = BigDecimal(value.to_s ) 
  #       TransactionActivity.create_custom_default_payment_savings_deduction_for_non_defaultee( non_defaultee_glm,
  #                                         payment_amount, employee)
  #     end
  #   else
  #     return nil 
  #   end
  # end
  # 
  # def execute_basic_default_payment_for_non_defaultee(employee)
  #   if not employee.has_role?(:branch_manager, employee.active_job_attachment) 
  #     return nil 
  #   end
  #   
  #   #  extract the sub_group amount
  #   #  extract the group_amount 
  #   #  kill it in one go 
  #   
  #   self.extract_sub_group_payment_contribution_for_non_defaultee
  #   self.extract_group_payment_contribution_for_non_defaultee
  #   
  #   self.non_defaultee_group_loan_memberships.each do |glm|
  #     TransactionActivity.create_basic_default_payment_savings_deduction_for_non_defaultee( non_defaultee_glm ,
  #                 employee)
  #   end
  # end
  # 
=begin
  Check grace period 
=end


  def is_grace_period?
    self.weekly_tasks.where(:is_weekly_payment_approved_by_cashier => true ).count == self.total_weeks 
  end
  
=begin
  New DEFAULT PAYMENT RESOLUTION MECHANISM: just pay for the principal + interest 
=end

  def default_payment_amount_to_be_shared
    active_glm_id_list  = self.active_group_loan_memberships.map {|x| x.id }

    total_to_be_shared = BigDecimal("0")
    
    DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => active_glm_id_list, 
      :is_defaultee => true 
      }).each do |dp| 
        
        total_to_be_shared += dp.amount_to_be_shared_with_non_defaultee
        
    end
  
    return total_to_be_shared
  end
  

  def update_default_payment_status
    self.active_group_loan_memberships.each do |glm|
      default_payment = glm.default_payment
      if glm.unpaid_backlogs.count != 0 
        default_payment.mark_as_defaultee
        default_payment.calculate_grace_period_amount
      else
        default_payment.mark_as_non_defaultee
      end
    end
  end

  def update_defaultee_default_payment_savings_deduction
    self.active_group_loan_memberships.each do |glm|
      glm.update_defaultee_savings_deduction
      # we update the amount to be shared with groups (non defaultee)
    end
  end

  def update_sub_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    self.sub_groups.each do |sub_group|
      sub_group.update_sub_group_default_payment_contribution(total_to_be_shared)
    end
  end
  
  def update_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    group_contribution = total_to_be_shared  * ( 50.0/100.0 )
    
    active_group_glm = self.active_group_loan_memberships.includes(:default_payment)
    active_group_glm_id_list = active_group_glm.map {|x| x.id }
    non_defaultee_default_payment = DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => active_group_glm_id_list, 
      :is_defaultee => false 
    })
    number_of_non_defaultee_in_group = non_defaultee_default_payment.length
    if number_of_non_defaultee_in_group >  0
       group_non_defaultee_contribution = group_contribution / number_of_non_defaultee_in_group
       
       non_defaultee_default_payment.each do |default_payment|
         default_payment.amount_group_share = group_non_defaultee_contribution
         default_payment.save
       end
    end 
  end
  
  
  def update_total_amount_in_default_payment
    self.active_group_loan_memberships.includes(:default_payment).each do |glm|
      default_payment = glm.default_payment 
      total_amount = BigDecimal("0")
      if default_payment.is_defaultee == true
        total_amount = default_payment.amount_of_compulsory_savings_deduction + default_payment.amount_of_extra_savings_deduction
        # puts "******!!!!!!!!!!In the shit, total_amount = #{total_amount}"
        default_payment.total_amount = total_amount
        
      elsif  default_payment.is_defaultee == false
        total_amount = default_payment.round_up_to( DEFAULT_PAYMENT_ROUND_UP_VALUE )
        total_compulsory_savings = glm.member.saving_book.total_compulsory_savings 
        if total_amount <= total_compulsory_savings
          default_payment.total_amount = total_amount
        else
          default_payment.total_amount =  total_compulsory_savings 
        end
      end
      
      default_payment.save
      
      # puts "!!# !!!!!!!!!!!!!!!In the shit, total_amount = #{default_payment.total_amount}"
      
      
    end
  end
  
  def calculate_default_payment_in_grace_period
    # this will be called on last weekly payment cashier approval
    # and after all the backlog payments  approval made in grace period 
    self.update_default_payment_status
    self.update_default_payment_in_grace_period
  end
  
  def update_default_payment_in_grace_period
    self.update_defaultee_default_payment_savings_deduction
    self.reload 
    total_to_be_shared = self.default_payment_amount_to_be_shared
    
    puts "Total to be shared: #{total_to_be_shared}\n"*5
    self.reload
    self.update_sub_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    self.reload
    self.update_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    self.reload
    self.update_total_amount_in_default_payment
  end
 
  
=begin
  PROPOSE default payment resolution with custom amount 
=end
  def active_glm_id_list
    self.active_group_loan_memberships.map{|x| x.id }
  end

  def min_shared_default_payment
    active_glm_id_list = self.active_glm_id_list
    total_sum = BigDecimal("0")
    DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => active_glm_id_list , 
      :is_defaultee => false 
    }).each do |dp|
      total_sum += dp.total_amount 
    end
    
    
    return total_sum
  end
  
  def propose_default_payment_execution_custom_value(employee, glm_amount_pair)
    if not employee.has_role?(:field_worker, employee.active_job_attachment)
      puts "wrong role"
      return nil
    end
    
    
    # all glm must be non defaultee 
    
    # total amount in the glm amount pair must be at least equal to the total suggested amount
    
    # each custom amount must be in 500 denomination -> not implemented yet 
    
    # the custom amount must be equal or bigger than the total compulsory savings
    
    # the sum of total amount by non defaultee
    min_shared_default_payment = self.min_shared_default_payment 
    
    active_glm = self.active_group_loan_memberships.includes(:default_payment, :member )
    active_glm_id_list = active_glm.collect {|x| x.id }
    proposed_glm_id_list = []
    
   
    
    glm_amount_pair.each do |key, value|
      proposed_glm_id_list << key 
    end
    
    if ( proposed_glm_id_list.length != active_glm_id_list.length )  or 
        ( (proposed_glm_id_list - active_glm_id_list).length != 0  ) or 
        ( (active_glm_id_list  - proposed_glm_id_list).length != 0  )
        puts "wrong glm list "
      return nil
    end
    
    
    total_proposed_custom_value = BigDecimal("0")
    
    active_glm.each do |glm|
      default_payment = glm.default_payment
      
      custom_amount = glm_amount_pair[glm.id]
      
      
      if default_payment.is_defaultee == false 
        
        if custom_amount < BigDecimal("0") or custom_amount.nil?  or 
            custom_amount > glm.member.saving_book.total_compulsory_savings
            puts "wrong custom amount value"
          return nil
        end
        
        total_proposed_custom_value += custom_amount
        # default_payment.set_custom_amount( custom_amount ) # not touching the DB in this calculation 
      elsif default_payment.is_defaultee == true 
        # the amount deducted from compulsory savings for defaultee is
        # => default_payment.total_amount 
        # => this value can't be changed in the custom mode 
        if custom_amount != default_payment.total_amount 
          puts "custom_amount != total_amount"
          return nil
        end
      end
    end
    
    if total_proposed_custom_value < min_shared_default_payment
      # all default_payment.custom_amount == nil 
      puts "total proposed < total_shared "
      return nil
    end
    
    
    
    active_glm.each do |glm|
      default_payment = glm.default_payment
      custom_amount = glm_amount_pair[glm.id]
      
      if default_payment.is_defaultee == false 
        default_payment.set_custom_amount( custom_amount ) # not touching the DB in this calculation 
      end
    end
    
    propose_default_payment_execution(employee)
    
    # returning true, if it is successful
    return true 
  end

  def total_amount_deducted_for_default_payment_resolution
    total_amount = BigDecimal("0")
    self.active_group_loan_memberships.includes(:default_payment).each do |glm|
      total_amount += glm.default_payment.amount_to_be_paid
    end
    return total_amount
  end

=begin
  PROPOSE default payment resolution 
=end
  def propose_default_payment_execution(employee)
    if not employee.has_role?(:field_worker, employee.active_job_attachment)
      return nil
    end
    
    # check whether it has the project assignment 
    self.is_default_payment_resolution_proposed = true
    self.default_payment_proposer_id = employee.id 
    self.save 
  end
  
  def execute_default_payment_execution( employee ) 
    if not employee.has_role?(:cashier, employee.active_job_attachment)
      return nil
    end
    
    if self.is_default_payment_resolution_proposed == false
      return nil
    end
    
    # if it has been approved, no double approval 
    if self.is_default_payment_resolution_approved == true
      return nil 
    end
    
    if self.unpaid_backlogs.count >  0 
      self.active_group_loan_memberships.includes(:default_payment).each do |glm|
        default_payment = glm.default_payment 
        if default_payment.amount_to_be_paid !=  BigDecimal("0")
          transaction_activity = TransactionActivity.create_default_payment_resolution( default_payment,  employee  ) 
        end
      end
    end
    
    
    self.active_group_loan_memberships.each do |glm|
      glm.is_active = false 
      glm.deactivation_case = GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed]
      glm.save
    end
    
    self.is_default_payment_resolution_approved = true
    self.default_payment_resolution_approver_id = employee.id 
    self.save
  end
  
  
end
