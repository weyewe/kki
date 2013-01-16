class Member < ActiveRecord::Base
  attr_protected :id 
  has_many :group_loans, :through => :group_loan_memberships
  has_many :group_loan_memberships
  
  # saving_book will list all the record of the member's saving 
  has_one :saving_book
  # transaction_book will list all the record of member's transaction 
  has_one :transaction_book
  has_many :backlog_payments
  
  has_many :member_payment_histories
  has_many :member_payments 

  belongs_to :office 
  # belongs_to :commune
  
  after_create :create_saving_book, :create_transaction_book
  
  validates_presence_of :name, :id_card_no , :commune_id 
  
  validates :id_card_no, :uniqueness => { 
    :case_sensitive => false,
    :message => "Harus unik. Sudah ada member dengan no KTP ini." }
 

  def group_loan_membership_for(group_loan)
    GroupLoanMembership.where(:is_active => true, :group_loan_id => group_loan.id, :member_id => self.id ).first
  end

  def past_group_loans
    member_id = self.id
    GroupLoanMembership.joins(:group_loan).where(
    { :member_id => member_id   } & 
    {:group_loan => {:is_started => true }} & 
    {:group_loan => {:is_closed => true }}
    ).count
  end
  
  def past_group_loan_memberships
    self.group_loan_memberships.where(:is_active => false )
  end

  def current_assigned_group_loans
    # member_id = self.id
    
    self.group_loan_memberships.joins(:group_loan).where(
      {:is_active => true }  & 
      {:group_loan => {:is_started => false }}
    )
    # GroupLoanMembership.joins(:group_loan).where(
    # { :member_id => member_id   } &  
    # {:group_loan => {:is_closed => false }}
    # )
  end

  def current_active_group_loans
    # member_id = self.id
    # GroupLoanMembership.joins(:group_loan).where(
    # { :member_id => member_id   } &  
    # {:group_loan => {:is_closed => false }} & 
    # {:group_loan => {:is_started => true }} 
    # ).count
    # 
    self.group_loan_memberships.joins(:group_loan).where(
      {:is_active => true }  & 
      {:group_loan => {:is_started => true }} & 
      {:group_loan => {:is_closed => false}}
    )
  end

=begin
  On Group Loan Start
=end
  def destroy_non_started_group_loan_memberships(active_group_loan) 
    current_assigned_group_loans.each do |glm|
      if glm.group_loan_id != active_group_loan.id 
        glm.destroy 
      end
    end
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
  
  # def add_savings(saving_amount, saving_entry_code, saving_transaction_entry )
  #    self.create_saving( saving_amount, saving_entry_code, SAVING_ACTION_TYPE[:debit] ,saving_transaction_entry)
  #  end
  
  def add_extra_savings(saving_amount, saving_entry_code, saving_transaction_entry )
    self.create_saving( saving_amount, saving_entry_code, SAVING_ACTION_TYPE[:debit] ,saving_transaction_entry, true)
  end
  
  def add_compulsory_savings(saving_amount, saving_entry_code, saving_transaction_entry )
    self.create_saving( saving_amount, saving_entry_code, SAVING_ACTION_TYPE[:debit] ,saving_transaction_entry, false)
  end
  
  # def deduct_savings( saving_amount, saving_entry_code, saving_transaction_entry)
  #   self.create_saving( saving_amount, saving_entry_code, SAVING_ACTION_TYPE[:credit], saving_transaction_entry )
  # end
  
  def deduct_extra_savings( saving_amount, saving_entry_code, saving_transaction_entry )
    self.create_saving( saving_amount, saving_entry_code, SAVING_ACTION_TYPE[:credit], saving_transaction_entry , true )
  end
  
  def deduct_compulsory_savings( saving_amount, saving_entry_code, saving_transaction_entry )
    self.create_saving( saving_amount, saving_entry_code, SAVING_ACTION_TYPE[:credit], saving_transaction_entry , false )
  end
  
  def port_compulsory_savings_to_extra_savings( total_amount , group_loan ) 
    self.create_saving( total_amount, SAVING_ENTRY_CODE[:deduct_compulsory_savings_to_be_ported_to_extra_savings], SAVING_ACTION_TYPE[:credit], saving_transaction_entry , false )
    self.create_saving( total_amount, SAVING_ENTRY_CODE[:add_extra_savings_from_compulsory_savings_deduction], SAVING_ACTION_TYPE[:debit], saving_transaction_entry , false )
  end
  
  
  
=begin
  FOR THE CORE, non product : loan or savings 
=end
  def create_saving( saving_amount, saving_entry_code, saving_action_type, saving_transaction_entry, is_extra_savings)
    saving_entry =  SavingEntry.create(
      :saving_book_id => self.saving_book.id , 
      :saving_entry_code => saving_entry_code,
      :amount => saving_amount,
      :saving_action_type => saving_action_type,
      :transaction_entry_id => saving_transaction_entry.id
    )
    
    
    self.saving_book.update_total( saving_entry, is_extra_savings)
    return saving_entry
  end
  
  def deduct_saving
  end
  
  
  
  def total_savings
    self.saving_book.total 
  end
  
  def can_pay_with_savings?( total_fee )
    self.saving_book.total_extra_savings >= total_fee
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
  
  
=begin
  SPECIAL FOR SAVINGS ACCOUNT
=end

  def add_savings_account(saving_amount, saving_entry_code, saving_transaction_entry )
    # self.create_saving( saving_amount, 
        # saving_entry_code, 
        # SAVING_ACTION_TYPE[:debit] ,
        # saving_transaction_entry, true)
    saving_entry =  SavingEntry.create(
      :saving_book_id => self.saving_book.id , 
      :saving_entry_code => saving_entry_code,
      :amount => saving_amount,
      :saving_action_type => SAVING_ACTION_TYPE[:debit] ,
      :transaction_entry_id => saving_transaction_entry.id,
      :savings_case => SAVING_CASE[:savings_account]
    )
     
    
    self.saving_book.update_total_savings_account( saving_entry )
    return saving_entry
  end
  
  def withdraw_savings_account(saving_amount, saving_entry_code, saving_transaction_entry )
    # self.create_saving( saving_amount, 
        # saving_entry_code, 
        # SAVING_ACTION_TYPE[:debit] ,
        # saving_transaction_entry, true)
    saving_entry =  SavingEntry.create(
      :saving_book_id => self.saving_book.id , 
      :saving_entry_code => saving_entry_code,
      :amount => saving_amount,
      :saving_action_type => SAVING_ACTION_TYPE[:credit] ,
      :transaction_entry_id => saving_transaction_entry.id,
      :savings_case => SAVING_CASE[:savings_account]
    )
     
    
    self.saving_book.update_total_savings_account( saving_entry )
    return saving_entry
  end
  
  
  protected
  
  def create_saving_book
    SavingBook.create(:member_id => self.id )
  end
  
  def create_transaction_book
    TransactionBook.create(:member_id => self.id )
  end

  
end
