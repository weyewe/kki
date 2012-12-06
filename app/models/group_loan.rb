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
    ( active_group_loan_memberships  + self.group_loan_memberships.where(:is_active => false , 
    :deactivation_case => GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed]) ) .sort_by{|x| x.sub_group_id}
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
  
  def potential_loan_disbursement_receivers
    self.group_loan_memberships.where{
      ( is_active.eq true) | 
      ( ( is_active.eq false ) & (deactivation_case.eq GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_disbursement_absent]))
    }.order("sub_group_id DESC")
  end
  
  def actual_loan_disbursement_receivers
    self.group_loan_memberships.where{
      ( is_active.eq true) | 
      ( ( is_active.eq false ) & (deactivation_case.eq GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_disbursement_absent]))
    }.where(:has_received_loan_disbursement => true )
  end
  
  def total_withdrawn_amount
    value = BigDecimal("0")
    # self.group_loan_memberships.where(:is_attending_financial_lecture => true).each do |glm|
    #     value += glm.group_loan_product.loan_amount_deducted_by_setup_amount
    #   end
    
    self.potential_loan_disbursement_receivers.each do |glm|
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
  
  def approve_loan_disbursement_with_setup_payment_deduction(employee)
    return nil if not employee.has_role?(:cashier, employee.active_job_attachment)
    
    active_member_id_list =  GroupLoanMembership.where(:id => active_glm_id_list ).map{|x| x.member_id }
    
    TransactionActivity.where(:member_id => active_member_id_list , :loan_type => LOAN_TYPE[:group_loan],
    :loan_id => self.id, :is_approved => false,
    :transaction_case => TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction]  ).each do |ta|
        ta.is_approved  = true 
        ta.approver_id = employee.id
        ta.save
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
      
      self.approve_loan_disbursement_with_setup_payment_deduction(current_user)
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
  
  def currently_pending_approval_weekly_task
    self.weekly_tasks.find(:first, :conditions => {
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
    group_loan = self 
    # MemberPayment.joins(:weekly_task).
    #           where(:member_id => member.id ,
    #           :weekly_task => {:group_loan_id => group_loan.id },
    #           :only_extra_savings => false )
              
    # Person.joins(:articles => :comments).
    #          where(:articles => {:comments => {:body.matches => 'Hello!'}})
    MemberPayment.joins(:weekly_task).
            where{
              (member_id.eq member.id ) & 
              (week_number.not_eq nil) &
              ( weekly_task.group_loan_id.eq group_loan.id )
            }
              
  end
  
  def remaining_weekly_tasks_count_for_member(member)
    number_of_accounted_weeks = self.accounted_weekly_payments_by(member).count
    remaining_weeks_count = self.weekly_tasks.count - number_of_accounted_weeks
  end
  

  
  
=begin
  GRACE PERIOD PAYMENT
=end
  def unpaid_backlogs
    self.backlog_payments.where(:is_cleared => false )
  end
  
  
  def unpaid_grace_period_amount
    sum = BigDecimal("0")
    DefaultPayment.where( :group_loan_membership_id => active_glm_id_list,
    :is_defaultee => true).each do |x|
      sum += x.unpaid_grace_period_amount 
    end
    return sum 
  end
  
  def deducted_grace_period_amount
    sum = BigDecimal("0")
    
    sum = DefaultPayment.where(:group_loan_membership_id => active_glm_id_list ).
          sum("amount_paid")
    
    return sum
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
    active_member_id_list = self.active_group_loan_memberships.map{|x| x.member_id }
    
    TransactionActivity.where(:member_id => active_member_id_list, 
                              :loan_id => self.id, 
                              :loan_type => LOAN_TYPE[:group_loan],
                              :transaction_case => (GRACE_PERIOD_PAYMENT_START..GRACE_PERIOD_PAYMENT_END),
                              :is_approved => false ,
                              :is_deleted => false ,
                              :is_canceled => false   )
                              
                              
    
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

  def total_default_payment_paid_by_office
    members_paid_default_payment.sum("amount_assumed_by_office")
  end
  
 
  
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
    
    if  self.is_default_payment_resolution_approved == true   
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
      self.is_grace_period = false
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
 
  
  def deduct_defaultee_compulsory_savings(employee)
    if not employee.has_role?(:branch_manager, employee.active_job_attachment ) 
      return nil 
    end
    
    @group_loan.group_loan_defaultees.each do |default_glm|
      TransactionActivity.create_default_payment_savings_deduction( default_glm, employee )
    end
    
    # we will have arrays of default payment, containing the amount deducted, default payment type == defaultee_savings_deduction
    
  end
  
 
=begin
  Check grace period 
=end


  def is_grace_period?
    self.weekly_tasks.where(:is_weekly_payment_approved_by_cashier => true ).count == self.total_weeks 
  end
  
=begin
  New DEFAULT PAYMENT RESOLUTION MECHANISM: just pay for the principal + interest 
=end

  def default_group_loan_memberships
    GroupLoanMembership.joins(:default_payment).where(:default_payment => {:is_defaultee => true},
      :is_active => true)
  end

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


  # for those defaultee, update the amount of compulsory savings deduction
  # extra savings deduction, and amount to be shared 
  def update_defaultee_default_payment_savings_deduction
    # puts "Updating the default payment\n"*5
    self.active_group_loan_memberships.each do |glm|
      glm.update_defaultee_savings_deduction
      # we update the amount to be shared with groups (non defaultee)
    end
  end

  def update_sub_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    self.sub_groups.each do |sub_group|
      # sub_group.update_sub_group_default_payment_contribution(total_to_be_shared)
      sub_group.update_sub_group_default_payment_contribution
    end
  end
  
  def update_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    group_contribution = self.sub_groups.sum("sub_group_default_payment_contribution_amount")  * ( 50.0/100.0 )
    
    active_group_glm = self.active_group_loan_memberships.includes(:default_payment)
    active_group_glm_id_list = active_group_glm.map {|x| x.id }
    # non_defaultee_default_payment = DefaultPayment.find(:all, :conditions => {
    #   :group_loan_membership_id => active_group_glm_id_list, 
    #   :is_defaultee => false 
    # })
    
    non_default_payment = [] 
    DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => active_group_glm_id_list 
    }).each do |default_payment|
      if default_payment.is_actual_non_defaultee? # default_payment.is_defaultee == false or 
      #           ( default_payment.is_defaultee == true and default_payment.unpaid_grace_period_amount == BigDecimal('0') ) 
        non_default_payment << default_payment
      end
    end
    
    number_of_non_defaultee_in_group = non_default_payment.length
    if number_of_non_defaultee_in_group >  0
       group_non_defaultee_contribution = group_contribution / number_of_non_defaultee_in_group
       
       non_default_payment.each do |default_payment|
         default_payment.amount_group_share = group_non_defaultee_contribution
         default_payment.save
       end
    end 
  end
  
  
  def update_total_amount_in_default_payment
    self.active_group_loan_memberships.includes(:default_payment).each do |glm|
      default_payment = glm.default_payment 
      total_amount = BigDecimal("0")
      member = glm.member
      total_savings = member.saving_book.total
      total_compulsory_savings = member.saving_book.total_compulsory_savings
      total_extra_savings = member.saving_book.total_extra_savings
      # remember, those defaultee that has paid all grace period is treated as non defaultee 
      if not default_payment.is_actual_non_defaultee? # default_payment.is_defaultee == true and default_payment.unpaid_grace_period_amount != BigDecimal('0')
        total_amount = default_payment.amount_of_compulsory_savings_deduction + default_payment.amount_of_extra_savings_deduction
        
        rounded_up_total_amount  = DefaultPayment.rounding_up( total_amount, DEFAULT_PAYMENT_ROUND_UP_VALUE ) 
        
        remnant = rounded_up_total_amount  - default_payment.amount_of_compulsory_savings_deduction 
        
        if remnant <= total_extra_savings 
          default_payment.amount_of_extra_savings_deduction = remnant
        else
          default_payment.amount_of_extra_savings_deduction = total_extra_savings
        end
        
        
        default_payment.total_amount = rounded_up_total_amount # => total_amount is not what deducted. it is what ideally being deducted,
        # despite the amount of compulsory savings and extra savings 
        # the actual amount paid is in the amount paid 
        default_payment.amount_paid = default_payment.amount_of_compulsory_savings_deduction  + default_payment.amount_of_extra_savings_deduction
        default_payment.amount_assumed_by_office = BigDecimal("0")
        
      elsif  default_payment.is_actual_non_defaultee?
        total_amount = default_payment.amount_sub_group_share + default_payment.amount_group_share
        rounded_up_total_amount  = DefaultPayment.rounding_up( total_amount , DEFAULT_PAYMENT_ROUND_UP_VALUE) 
        
        # total_amount = default_payment.round_up_to( DEFAULT_PAYMENT_ROUND_UP_VALUE )
        
        if rounded_up_total_amount <= total_compulsory_savings
          default_payment.amount_of_compulsory_savings_deduction = rounded_up_total_amount 
        else
          default_payment.amount_of_compulsory_savings_deduction = total_compulsory_savings
        end
        default_payment.amount_of_extra_savings_deduction  = BigDecimal("0") # office won't deduct non-defaultee voluntary savings
        default_payment.total_amount = rounded_up_total_amount
        default_payment.amount_paid = default_payment.amount_of_compulsory_savings_deduction
        default_payment.amount_assumed_by_office = rounded_up_total_amount - default_payment.amount_of_compulsory_savings_deduction
      end
      
      # actually,total_payment= DefaultPayment.where(:group_loan_membership_id => active_glm_id_list).sum("amount_paid")
      # total amount assumed by office = DefaultPayment.where(:group_loan_membership_id => active_glm_id_list, :is_default => true ).sum("total_grace_period_amount") - 
      #  DefaultPayment.where(:group_loan_membership_id => active_glm_id_list, :is_default => true ).sum("paid_grace_period_amount") 
      default_payment.save
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
    # puts "inside the group_loan#update_default_payment_in_grace_period"
    # puts "Total to be shared: #{total_to_be_shared}\n"*5
    self.reload
    self.update_sub_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    self.reload
    self.update_group_non_defaultee_default_payment_contribution(total_to_be_shared)
    # we have updated default payment # amount of group share and amount of sub group share for non defaultee 
    self.reload
    self.update_total_amount_in_default_payment
    # self.rounding_up_in_savings_deduction_for_default_payment
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
   
  
  def propose_custom_default_payment_execution(employee, glm_payment_pair_list)
    
    if not employee.has_role?(:field_worker, employee.active_job_attachment)
      return nil
    end
    
    if self.pending_approval_grace_period_transactions.count != 0 
      return nil
    end
    
    
    glm_list = self.active_group_loan_memberships.map{|x| x.id } 
    glm_list_from_params = [] 
    total_amount= BigDecimal('0')
    glm_payment_pair_list.map do |x| 
      glm_list_from_params << x[:glm_id]
      total_amount += x[:amount]
      glm = self.active_group_loan_memberships.where( :id =>x[:glm_id] ) .first
      
      return nil if glm.member.saving_book.total_compulsory_savings < x[:amount] 
    end
    
    # all active glm must be in the list
    return nil if (glm_list - glm_list_from_params).length != 0 
    return nil if self.unpaid_grace_period_amount !=  total_amount
    
    
    glm_payment_pair_list.map do |x|  
      glm = self.active_group_loan_memberships.where( :id =>x[:glm_id] )  
      default_payment = DefaultPayment.find_by_group_loan_membership_id x[:glm_id]
      default_payment.custom_amount = x[:amount]
      default_payment.save 
    end
    
    # check whether it has the project assignment 
    self.is_default_payment_resolution_proposed = true
    self.default_payment_proposer_id = employee.id 
    self.is_custom_default_payment_resolution = true 
    self.save 
    
  end

  def total_amount_deducted_for_default_payment_resolution
    total_amount = BigDecimal("0")
    self.active_group_loan_memberships.includes(:default_payment).each do |glm|
      total_amount += glm.default_payment.amount_to_be_paid
    end
    return total_amount
  end
  
  def total_amount_deducted_for_custom_default_payment_resolution
    total_amount = BigDecimal("0")
    self.active_group_loan_memberships.includes(:default_payment).each do |glm|
      total_amount += glm.default_payment.custom_amount
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
    
    if self.pending_approval_grace_period_transactions.count != 0 
      return nil
    end
    
    # check whether it has the project assignment 
    self.is_default_payment_resolution_proposed = true
    self.default_payment_proposer_id = employee.id 
    self.save 
  end
  
  def cancel_default_payment_proposal(employee)
    if not employee.has_role?(:cashier, employee.active_job_attachment)
      return nil
    end
    
    if self.is_default_payment_resolution_approved == true 
      return nil
    end
    
    self.is_default_payment_resolution_proposed = false
    self.is_custom_default_payment_resolution = false
    self.default_payment_proposer_id = nil 
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
    
    #  if there is stil unapproved independent payment? 
    
    self.active_group_loan_memberships.includes(:default_payment).each do |glm|
      default_payment = glm.default_payment 
      if self.is_custom_default_payment_resolution == false 
        transaction_activity = TransactionActivity.create_default_payment_resolution( default_payment,  employee  ) 
      else
        transaction_activity = TransactionActivity.create_custom_default_payment_resolution( default_payment,  employee  ) 
      end
    end
    
    
    # self.active_group_loan_memberships.each do |glm|
    #   glm.is_active = false 
    #   glm.deactivation_case = GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed]
    #   glm.save
    # end
    
    self.is_default_payment_resolution_approved = true
    self.default_payment_resolution_approver_id = employee.id 
    self.save
  end
  
  
end
