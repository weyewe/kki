class SavingEntry < ActiveRecord::Base
  belongs_to :saving_book 
  belongs_to :transaction_entry 
  
  # after_create :update_saving_book
  
  # belongs_to :transaction_entry
  
  
  # def update_saving_book
  #    saving_book = self.saving_book
  #    total = saving_book.total
  #    if self.saving_action_type == SAVING_ACTION_TYPE[:debit]
  #      total += self.amount 
  #    elsif self.saving_action_type == SAVING_ACTION_TYPE[:credit]
  #      total -= self.amount
  #    end
  #    saving_book.total = total
  #    saving_book.save  
  #  end
  
end
