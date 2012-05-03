class Member < ActiveRecord::Base
  has_many :group_loans, :through => :group_loan_memberships
  has_many :group_loan_memberships
  
  # saving_book will list all the record of the member's saving 
  has_one :saving_book
  # transaction_book will list all the record of member's transaction 
  has_one :transaction_book
  has_many :backlog_payments

  belongs_to :office 
  # belongs_to :commune
  
  after_create :create_saving_book, :create_transaction_book
  
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
  
  def is_sub_group_group_loan_member?(group_loan_membership , sub_group)
    group_loan_membership == sub_group.id 
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
  
  def add_savings(saving_amount, saving_entry_code )
    return SavingEntry.create(
      :saving_book_id => self.saving_book.id , 
      :saving_entry_code => saving_entry_code, 
      :amount => saving_amount, 
      :saving_action_type => SAVING_ACTION_TYPE[:debit]
    )
  end
  
  def deduct_savings( saving_amount, saving_entry_code)
    self.saving_book.saving_entries.create(
      :saving_entry_code => saving_entry_code,
      :amount => saving_amount,
      :saving_action_type => SAVING_ACTION_TYPE[:credit]
    )
  end
  
  def total_savings
    self.saving_book.total 
  end
  
  def can_pay_with_savings?( total_fee )
    self.total_savings >= total_fee
  end
  
=begin
  Backlog Payment 
=end

  def has_backlog_payments_for_group_loan?( group_loan ) 
    self.backlog_payments.where(:group_loan_id => group_loan.id ).count > 0 
  end
  
  def backlog_payments_for_group_loan( group_loan)
    self.backlog_payments.where(:group_loan_id => group_loan.id )
  end
  
  def uncleared_backlog_payments_for_group_loan( group_loan)
    self.backlog_payments.where(:group_loan_id => group_loan.id, :is_cleared => false  )
  end
  
  def cleared_backlog_payments_for_group_loan( group_loan)
    self.backlog_payments.where(:group_loan_id => group_loan.id, :is_cleared => true  )
  end
  
  def total_backlog_payments_for_group_loan( group_loan) 
    backlog_payments_for_group_loan(group_loan).count 
  end
  
 
  
  protected
  
  def create_saving_book
    SavingBook.create(:member_id => self.id )
  end
  
  def create_transaction_book
    TransactionBook.create(:member_id => self.id )
  end

  
end
