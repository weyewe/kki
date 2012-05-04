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
                  :is_loan_disbursement_done, :loan_disburser_id,
                  :aggregated_principal_amount, :aggregated_interest_amount,
                  :total_default, :default_creator_id ,
                  :group_leader_id
                  
  
  
  
  
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

  def execute_propose_finalization( current_user )
    if self.unassigned_members.count != 0  or self.equal_loan_duration == false 
      return nil
    else
      self.is_proposed = true 
      self.group_loan_proposer_id = current_user.id 
      self.save 
    end
  end
  
  def is_rejected?
    self.is_proposed == false && self.is_started == false 
  end
    
  def start_group_loan( current_user )
   
    
    if all_members_have_equal_loan_duration?
      self.is_started = true 
      self.group_loan_starter_id = current_user.id 
      self.total_weeks = self.total_loan_duration
      self.save
    else
      return nil
    end
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
    self.group_loan_memberships.where(:has_received_loan_disbursement => true )
  end
  
  def undisbursed_members
    self.group_loan_memberships.where(:has_received_loan_disbursement => false )
  end
  
  def total_disbursement_amount
    value = BigDecimal.new('0')
    self.group_loan_memberships.each {|x|  value += x.group_loan_product.loan_amount }
    
    return value
  end
  
  def execute_finalize_loan_disbursement( current_user )
    
    
    if self.undisbursed_members.count != 0 
      return false
    else
      self.is_loan_disbursement_done = true 
      self.loan_disburser_id = current_user.id
      self.save 
      
      
      self.initiate_weekly_tasks
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
  
  def accounted_weekly_payments_by(member)
    weekly_task_id_list = self.weekly_tasks.collect do |weekly_task|
      weekly_task.id
    end
    MemberPayment.find(:all,:conditions => {
      :member_id => member.id, 
      :weekly_task_id => weekly_task_id_list
    }).map{|x| x.weekly_task}
  end
  
  def remaining_weekly_tasks_count_for_member(member)
    number_of_accounted_weeks = self.accounted_weekly_payments_by(member).count
    remaining_weeks_count = self.weekly_tasks.count - number_of_accounted_weeks
  end
  
  # def total_remaining_weekly_tasks
  #     self.total_weeks - self.completed_weekly_tasks.count
  #   end
  
  def declare_default( current_user )
    if not current_user.has_role?(:branch_manager)
      return nil
    end
    
    # put this in transaction block
    self.default_creator_id = current_user.id
    self.is_group_loan_default = true 
    self.save 
    self.generate_default_payments
    
  end
  
  
  def extract_total_default_amount
    total_default = BigDecimal("0")
    
    self.unpaid_backlogs.each do |backlog|
      total_default += backlog.amount
    end
    
    self.total_default_amount  =  total_default
    self.save 
    
    return total_default
  end
  
  def declare_backlog_payments_as_default
    self.unpaid_backlogs.each do |backlog|
      backlog.is_group_loan_declared_as_default = true
      backlog.save
    end
  end
  
  def unpaid_backlogs
    self.backlog_payments.where(:is_cleared => false )
  end
  
  def extract_default_member_id
    list_of_default_member_id = BacklogPayment.list_member_id_with_default_in_group_loan( self ) 
  end
  
  def extract_non_default_member_id
    list_of_default_member_id = self.extract_default_member_id
    all_member_id = []
    self.group_loan_memberships.each do |glm|
      all_member_id << glm.member_id
    end
    
    all_member_id - list_of_default_member_id
  end
  
  def group_loan_membership_id_list 
    self.group_loan_memberships.collect{|x| x.id }
  end
  
  
  
  def generate_default_payments_per_group_loan_membership
    total_default = self.total_default_amount
    self.group_loan_memberships.each do |glm|
      DefaultPayment.create :group_loan_membership_id => glm.id 
    end
    
    # get all member without default 
    
    
    list_of_non_default_member_id = self.extract_non_default_member_id
    if list_of_non_default_member_id.length == 0 
      #  set the amount of KKI has to pay
      self.total_default_amount = total_default
      self.save 
      return nil # fuck.. everyone is defaulting who should pay? KKI? 
    end
    
    group_share_amount =  ( total_default/2 ) / list_of_non_default_member_id.length 
    
    
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
    end
    
    
    # we want the sum of total sub_group_share + group_share default payment, so that we will know the 
    # amount absorbed by kki  << important
    
    # group_loan_membership_id_list = self.extract_group_loan_membership_id_list
    total_amount_subgroup_share = DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => self.group_loan_membership_id_list
    }).sum("amount_subgroup_share")
    
    total_amount_group_share = DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => self.group_loan_membership_id_list
    }).sum("amount_group_share")
    
    total_amount_absorbed_by_office = total_default - total_amount_subgroup_share - total_amount_group_share
    self.total_calculated_default_absorbed_by_office= total_amount_absorbed_by_office
    self.save 
  end
  
  def generate_default_payments
    self.extract_total_default_amount
    self.generate_default_payments_per_group_loan_membership 
    self.declare_backlog_payments_as_default
  end
  
  
  
  
end
