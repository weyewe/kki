class Member < ActiveRecord::Base
  has_many :group_loans, :through => :group_loan_memberships
  has_many :group_loan_memberships
  
  # saving_book will list all the record of the member's saving 
  has_one :saving_book
  # transaction_book will list all the record of member's transaction 
  has_one :transaction_book


  belongs_to :office 
  
  validates_presence_of :name, :id_card_no , :commune_id 
  
  validates :id_card_no, :uniqueness => { 
    :case_sensitive => false,
    :message => "Harus unik. Sudah ada member dengan no KTP ini." }
 

  def past_group_loans
    member_id = self.id
    GroupLoanMembership.joins(:group_loan).where(
    { :member_id => member_id   } & 
    {:group_loan => {:is_started => true }} & 
    {:group_loan => {:is_closed => true }}
    ).count
  end

  def current_assigned_group_loans
    member_id = self.id
    GroupLoanMembership.joins(:group_loan).where(
    { :member_id => member_id   } &  
    {:group_loan => {:is_closed => false }}
    ).count
  end

  def current_active_group_loans
    member_id = self.id
    GroupLoanMembership.joins(:group_loan).where(
    { :member_id => member_id   } &  
    {:group_loan => {:is_closed => false }} & 
    {:group_loan => {:is_started => true }} 
    ).count
  end


  def is_group_loan_member?(group_loan) 
    not GroupLoanMembership.find(:first, :conditions => {
      :member_id => self.id,
      :group_loan_id => group_loan.id 
      }).nil?
  end


  def get_group_loan_product_for(group_loan)
    group_loan_membership = group_loan.get_membership_for_member( self )
    
    group_loan_subcription = GroupLoanSubcription.find(:first, :conditions => {
      :group_loan_membership_id => group_loan_membership.id 
    })
    
    if group_loan_subcription.nil?
      return nil
    else
      return group_loan_subcription.group_loan_product
    end
  end

  
end
