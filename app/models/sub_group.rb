class SubGroup < ActiveRecord::Base
  has_many :group_loan_memberships 
  belongs_to :group_loan 
  
  before_destroy :set_group_loan_membership_sub_group_to_nil
  
  def self.set_sub_groups( group_loan, new_sub_groups )
    current_sub_groups = group_loan.sub_groups.count 
    if new_sub_groups > current_sub_groups 
       # create new sub_groups as normal 
      group_loan.sub_groups.create_extra_sub_groups( group_loan, new_sub_groups - current_sub_groups )
     
    elsif new_sub_groups < current_sub_groups 
      # delete extra sub_groups, move the sub_group_memberships to nothing  
      group_loan.sub_groups.delete_sub_groups( group_loan , current_sub_groups - new_sub_groups )
      
    elsif new_sub_groups == current_sub_groups
      
    end
  end
  
  
  
  def self.create_extra_sub_groups( group_loan, new_sub_groups_count )
    last_sub_group = SubGroup.last_sub_group( group_loan)
    number = 0 
    
    if last_sub_group.nil?
      number = 0
    else
      number = last_sub_group.number 
    end
    
    (1..new_sub_groups_count).each do |x|
      SubGroup.create :group_loan_id => group_loan.id , :number => ( number + x ) 
    end
    
  end
  
  def self.delete_sub_groups( group_loan , sub_groups_to_be_deleted)
    last_sub_group = SubGroup.last_sub_group( group_loan)
    number  = 0 
    
    # defensive programming
    if last_sub_group.nil? || ( group_loan.sub_groups.count < sub_groups_to_be_deleted ) 
      return
    else
      number = last_sub_group.number
    end
    
    SubGroup.find(:all, :conditions => {
      :group_loan_id => group_loan.id
    }, :limit =>sub_groups_to_be_deleted  , :order => "number DESC").each do |sub_group|
      sub_group.destroy 
    end
    
  end
  
  def self.last_sub_group( group_loan)
    SubGroup.find(:first, :conditions => {
      :group_loan_id => group_loan.id
    }, :order => "number DESC" )
  end
  
  
  
  
  def add_member( member )
    group_loan_membership = self.get_group_loan_membership( member ) 
    
    
    group_loan_membership.sub_group_id = self.id 
    group_loan_membership.sub_group_update_datetime = DateTime.now 
    group_loan_membership.save  
  end
  
  def remove_member(member )
    group_loan_membership = self.get_group_loan_membership( member ) 
    group_loan_membership.sub_group_id = nil
    group_loan_membership.sub_group_update_datetime = nil 
    group_loan_membership.save
  end
  
  def get_group_loan_membership( member ) 
    group_loan = self.group_loan 
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => group_loan.id,
      :member_id => member.id
    })
  end
  
=begin
  Set SubGroup Leader
=end

  def leader
    if self.sub_group_leader_id.nil?
      return nil
    else
      Member.find_by_id self.sub_group_leader_id 
    end
  end
  
  def set_group_leader( member )
    self.sub_group_leader_id = member.id 
    self.save
  end
  
  def remove_group_leader
    self.sub_group_leader_id =  nil 
    self.save
  end
  
  
  def active_group_loan_memberships 
    self.group_loan_memberships.where(:is_active => true )
  end
  
  
=begin
  NEW DEFAULT_PAYMENT SCHEMA
=end
  def update_sub_group_default_payment_contribution#(total_to_be_shared)
    # sub_group_contribution_amount = total_to_be_shared * ( 50.0/100.0)
    
    active_subgroup_glm = self.active_group_loan_memberships.includes(:default_payment)
    
    active_subgroup_glm_id_list  = active_subgroup_glm.map { |x| x.id  }
    
    sub_group_amount_to_be_shared = BigDecimal("0")
    # or those where amount to be paid != 0 
    defaultee_default_payment = DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => active_subgroup_glm_id_list, 
      :is_defaultee => true 
    }).each do |dp|
      sub_group_amount_to_be_shared += dp.amount_to_be_shared_with_non_defaultee
    end
    
    self.sub_group_default_payment_contribution_amount = sub_group_amount_to_be_shared
    self.save
    
    sub_group_contribution_amount = sub_group_amount_to_be_shared * ( 50.0/100.0)
    
    # the definition of non defaultee is changed.
    # now, those defaultee but amount to be paid ==0 is considered as  non defaulete 
    # non_defaultee_default_payment = DefaultPayment.find(:all, :conditions => {
    #   :group_loan_membership_id => active_subgroup_glm_id_list, 
    #   :is_defaultee => false 
    # })
    # cleared_defaultee_default_payment = []
    # DefaultPayment.find(:all, :conditions => {
    #   :group_loan_membership_id => active_subgroup_glm_id_list,
    #   :is_defaultee => true 
    # }).each do |defaultee|
    #   if defaultee.unpaid_grace_period_amount == BigDecimal('0')
    #     cleared_defaultee_default_payment << defaultee
    #   end
    # end
    # 
    non_default_payment = []
    
    
    DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => active_subgroup_glm_id_list
    }).each do |default_payment|
      if default_payment.is_actual_non_defaultee? # default_payment.is_defaultee == false or 
      #           ( default_payment.is_defaultee == true and default_payment.unpaid_grace_period_amount == BigDecimal('0') ) 
        non_default_payment << default_payment
      end
    end
    
    
    
    # definition of non defaultee over here == those that doesn't have unpaid backlogs during grace period + 
    # those that has paid all grace payment 
    number_of_non_defaultee_in_subgroup = non_default_payment.count
    if number_of_non_defaultee_in_subgroup  >  0 
      sub_group_contribution_per_non_defaultee = sub_group_contribution_amount / number_of_non_defaultee_in_subgroup
      
      non_default_payment.each do |default_payment|
        default_payment.amount_sub_group_share = sub_group_contribution_per_non_defaultee
        default_payment.save
      end
    end
  end


  
=begin
  SubGroup Default Payment
=end
  def extract_total_default( default_sub_group_member_id )
    total_default = BigDecimal("0")
    default_sub_group_member_id.each do |member_id|
      

      backlog_payments_count = BacklogPayment.find(:all, :conditions => {
        :member_id => member_id, 
        :group_loan_id => self.group_loan_id,
        :is_cleared => false 
      }).count

      total_default +=  backlog_payments_count * glm.group_loan_product.total_weekly_payment
    end
    
    
    return total_default 
  end

  def group_loan_membership_id_list 
    self.group_loan_memberships.collect{|x| x.id }
  end
  
  

  
  def round_up_total_default_payment
    self.group_loan_memberships.includes(:default_payment).each do |glm|
      default_payment = glm.default_payment
      
      default_payment.round_up_to( DEFAULT_PAYMENT_ROUND_UP_VALUE )
    end
  end
  
 
  def unpaid_backlogs 
    # find all unpaid backlogs from the member of this subgroup 
    sub_group_member_id_list = self.group_loan_memberships.map{|x| x.member_id }
    BacklogPayment.find(:all, :conditions => {
      :group_loan_id => self.group_loan_id,
      :member_id => sub_group_member_id_list,
      :is_cleared => false 
    })
  end
  
  def extract_total_unpaid_backlogs
    total_sum = BigDecimal("0")
    self.unpaid_backlogs.each do |backlog|
      member = backlog.member
      glm = self.group_loan.get_membership_for_member( member )
      group_loan_product = glm.group_loan_product
      total_sum += group_loan_product.total_weekly_payment 
    end
    self.sub_group_total_default_payment_amount = total_sum
    self.save 
    return total_sum 
  end
  
  
  def sub_group_member_id_list
    self.group_loan_memberships.map{|x| x.member_id}
  end
  
  def default_payments
    # return all default payment account 
    glm_id_list= self.group_loan_memberships.map{|x| x.id }
    
    DefaultPayment.find(:all, :conditions => {
      :group_loan_membership_id => glm_id_list
    })
  end
  
  def extract_default_member_id
    sub_group_member_id_list  - self.extract_non_default_member_id 
  end
  
  def extract_non_default_member_id
    #inspired from group_loan.extract_default_member_id
    default_member_id = self.group_loan.extract_default_member_id
    
    # sub_group_member_id_list = self.group_loan_memberships.map{|x| x.member_id}
    
    non_default_sub_group_member_id_list = self.sub_group_member_id_list - default_member_id
  end
  

  
  def total_default_member
    self.extract_default_member_id.length
  end
  
  
  protected 
  def set_group_loan_membership_sub_group_to_nil
    self.group_loan_memberships.each do |glm|
      glm.sub_group_id = nil
      glm.save 
    end
  end
end
