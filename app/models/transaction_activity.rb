=begin
  TransactionActivity is responsible to record the flow of $$$, from and to the member
  Flow from the member to company: in the form of 
    1. Payment
      - Setup Payment ( admin fee, deposit, initial savings )
      - Weekly Payment ( principal, interest, saving)
      - Fine for late weekly payment 
  
  Flow from the company to the member:
    1. Returning the deposit 
    2. Member withdraws $$ from savings
      - soft withdrawal (use the savings to pay for the loan)
      - hard withdrawal( take the cash )
  
=end

class TransactionActivity < ActiveRecord::Base
  has_many :transaction_entries 
  belongs_to :office 
  
  
  after_create :create_transaction_entries 
  # all data coming in are BigDecimal
  def self.create_setup_payment( admin_fee, initial_savings, deposit, field_worker, group_loan_membership )
    group_loan_product = group_loan_membership.group_loan_subcription.group_loan_product
    
    
    if initial_savings < group_loan_product.initial_savings  or 
            admin_fee < group_loan_product.admin_fee
      return nil
    end
    
    member = group_loan_membership.member 
    # group_loan = group_loan_membership.group_loan 
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = admin_fee +  initial_savings +  deposit
    new_hash[:transaction_case] = TRANSACTION_CASE[:setup_payment]
    new_hash[:creator_id] = field_worker.id 
    new_hash[:office_id] = field_worker.active_job_attachment.office.id
    new_hash[:member_id] = member.id 
    
    transaction_activity = TransactionActivity.create new_hash 
    group_loan_membership.deposit = deposit
    group_loan_membership.initial_savings = initial_savings
    group_loan_membership.admin_fee = admin_fee
    group_loan_membership.has_paid_setup_fee = true
    group_loan_membership.setup_fee_transaction_id = transaction_activity.id 
    group_loan_membership.save
    
    return transaction_activity 
    # group_loan.update_setup_deposit( group_loan_membership.deposit )
    # how can we create the transaction entries ?
  end
  
  
  def self.execute_loan_disbursement( group_loan_membership , cashier)
    group_loan_product = group_loan_membership.group_loan_product
    member = group_loan_membership.member 
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = group_loan_product.loan_amount
    new_hash[:transaction_case] = TRANSACTION_CASE[:loan_disbursement]
    new_hash[:creator_id] = cashier.id 
    new_hash[:office_id] = cashier.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    
    transaction_activity = TransactionActivity.create new_hash 
    
    group_loan_membership.has_received_loan_disbursement = true
    group_loan_membership.loan_disbursement_transaction_id = transaction_activity.id 
    group_loan_membership.save 
    
    return transaction_activity 
  end
  
  
  protected
  def create_transaction_entries
    puts "heheh, we are in the create_transaction_entries"
    # depending on the transaction_case, do different transaction_entries 
  end
end
