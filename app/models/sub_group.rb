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
    group_loan_membership.save  
  end
  
  def remove_member(member )
    group_loan_membership = self.get_group_loan_membership( member ) 
    group_loan_membership.sub_group_id = nil
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
  
  
  protected 
  def set_group_loan_membership_sub_group_to_nil
    self.group_loan_memberships.each do |glm|
      glm.sub_group_id = nil
      glm.save 
    end
  end
end
