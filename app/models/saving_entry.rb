class SavingEntry < ActiveRecord::Base
  belongs_to :saving_book 
  
  after_create :update_saving_book
  
  
  def update_saving_book
    if self.saving_action_type == SAVING_ACTION_TYPE[:debit]
      self.saving_book.total += self.amount 
    elsif self.saving_action_type == SAVING_ACTION_TYPE[:credit]
      self.saving_book.total -= self.amount
    end
    self.saving_book.save 
  end
  
end
