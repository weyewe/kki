class TransactionActivity < ActiveRecord::Base
  

  def TransactionActivity.has_unapproved_savings_account_transaction?(member)
    TransactionActivity.where(
      :transaction_case =>  (SAVINGS_ACCOUNT_START..SAVINGS_ACCOUNT_END),
      :is_approved => false  
    ).count != 0 
  end
  
  def is_savings_account_transaction?
    self.transaction_case >= SAVINGS_ACCOUNT_START && self.transaction_case <= SAVINGS_ACCOUNT_END
  end
  
  def delete_savings_account_transaction(employee)
    return nil if not  self.is_savings_account_transaction?
    return nil if not employee.has_role?(:cashier, employee.get_active_job_attachment)
    return nil if self.is_approved 
    
    self.destroy
  end

=begin
  SPECIAL FOR SAVINGS_ACCOUNT ADDITION
=end

  def TransactionActivity.add_savings_account( employee, member, amount)
    return nil if amount <= MIN_SAVINGS_ACCOUNT_AMOUNT 
    return nil if not employee.has_role?(:cashier, employee.get_active_job_attachment)
    return nil if TransactionActivity.has_unapproved_savings_account_transaction?(member)
    return nil if amount < MIN_SAVINGS_ACCOUNT_AMOUNT
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = amount
    new_hash[:transaction_case] = TRANSACTION_CASE[:add_savings_account]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id 
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward] 
    
    transaction_activity = TransactionActivity.create new_hash
    
    return transaction_activity 
  end
  
  def confirm_savings_account_addition( employee )
    return nil if not employee.has_role?(:cashier, employee.get_active_job_attachment)
    return nil if self.is_approved 
    
    # member = Member.find_by_id self.member_id 
    # return nil if TransactionActivity.has_unapproved_savings_account_transaction?(member)
    
    
    self.is_approved = true
    self.save 
    self.create_savings_account_addition_entry 
  end
  
  
  def create_savings_account_addition_entry
    amount = self.total_transaction_amount 
    transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code =>  TRANSACTION_ENTRY_CODE[:add_savings_account] , 
                      :amount => amount   ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
         
    member.add_savings_account(amount, SAVING_ENTRY_CODE[:add_savings_account] , transaction_entry  )
  end
  
=begin
  SPECIAL FOR SAVINGS_ACCOUNT WITHDRAWAL
=end
  
  def TransactionActivity.withdraw_savings_account( employee, member, amount)
    return nil if amount > member.saving_book.total_savings_account  
    return nil if not employee.has_role?(:cashier, employee.get_active_job_attachment)
    return nil if TransactionActivity.has_unapproved_savings_account_transaction?(member)
    return nil if amount < MIN_SAVINGS_ACCOUNT_AMOUNT
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = amount
    new_hash[:transaction_case] = TRANSACTION_CASE[:withdraw_savings_account]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id 
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:outward] 
    
    transaction_activity = TransactionActivity.create new_hash
    
    return transaction_activity
    
  end
  
  def confirm_savings_account_withdrawal( employee )
    return nil if not employee.has_role?(:cashier, employee.get_active_job_attachment)
    return nil if self.is_approved 
    
    # member = Member.find_by_id self.member_id 
    # return nil if TransactionActivity.has_unapproved_savings_account_transaction?(member)
    
    
    self.is_approved = true
    self.save 
    self.create_savings_account_withdrawal_entry
  end
  
  def create_savings_account_withdrawal_entry
    amount = self.total_transaction_amount 
    transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code =>  TRANSACTION_ENTRY_CODE[:withdraw_savings_account] , 
                      :amount => amount   ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
         
    member.withdraw_savings_account(amount, SAVING_ENTRY_CODE[:withdraw_savings_account] , transaction_entry  )
  end
  
  # produce interest? => from the company to the members 
  
  
end