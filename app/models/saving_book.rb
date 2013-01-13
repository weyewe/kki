=begin
Saving Book is used to handle Loan Product => group loan or personal loan 

It is clearly not a good way to name the Model. However, the software did evolved, following
the business evolution.

History:
1. Initially this software is used only for recording group loan, to help microfinance
2. As the microfinance progressed, it is found that the poor are responding to savings. However, 
no bank product that can cater to their need. 

3. Hence, we upgrade the software to handle savings account like those in the bank (with monthly interest rate)

4. The model used to handle normal savings account => SavingAccount , the entries: SavingAccountEntry
=end

class SavingBook < ActiveRecord::Base
  belongs_to :member
  has_many :saving_entries
  
  def revert_transaction_add_extra_savings(amount)
    self.total_extra_savings += amount
    self.total += amount
    self.save
  end
  
  def revert_transaction_deduct_extra_savings(amount)
    self.total_extra_savings -= amount
    self.total -= amount
    self.save
  end
  
  def revert_transaction_deduct_compulsory_savings(amount)
    self.total_compulsory_savings -= amount
    self.total -= amount
    self.save
  end
  
  def update_total(saving_entry, is_extra_savings)
    total_amount = self.total
    total_compulsory_savings = self.total_compulsory_savings
    total_extra_savings = self.total_extra_savings
    
    if saving_entry.saving_action_type == SAVING_ACTION_TYPE[:debit]
      total_amount += saving_entry.amount 
      if is_extra_savings == true
        total_extra_savings += saving_entry.amount
      elsif is_extra_savings == false
        total_compulsory_savings += saving_entry.amount
      end
    elsif saving_entry.saving_action_type == SAVING_ACTION_TYPE[:credit]
      total_amount -= saving_entry.amount
      
      if is_extra_savings
        total_extra_savings -= saving_entry.amount
      else
        total_compulsory_savings -= saving_entry.amount
      end
    end
    
    self.total = total_amount
    self.total_compulsory_savings = total_compulsory_savings
    self.total_extra_savings = total_extra_savings
    self.save
    
    saving_entry.saving_book_id = self.id
    saving_entry.save 
  end
  
  def update_total_savings_account( saving_entry) 
    # ensure that this shite is indeed savings account 
    return nil if saving_entry.savings_case != SAVING_CASE[:savings_account] 
    
    total_amount = self.total_savings_account 
    
    if saving_entry.saving_action_type == SAVING_ACTION_TYPE[:debit]
      total_amount += saving_entry.amount  
    elsif saving_entry.saving_action_type == SAVING_ACTION_TYPE[:credit]
      total_amount -= saving_entry.amount
    end
    
    self.total_savings_account = total_amount 
    self.save
    saving_entry.saving_book_id = self.id
    saving_entry.save
  end
end
