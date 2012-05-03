class SavingBook < ActiveRecord::Base
  belongs_to :member
  has_many :saving_entries
  
  def update_total(saving_entry)
    total_amount = self.total
    
    if saving_entry.saving_action_type == SAVING_ACTION_TYPE[:debit]
      total_amount += saving_entry.amount 
    elsif saving_entry.saving_action_type == SAVING_ACTION_TYPE[:credit]
      total_amount -= saving_entry.amount
    end
    
    self.total = total_amount
    self.save
    
    saving_entry.saving_book_id = self.id
    saving_entry.save
    
    
  end
end
