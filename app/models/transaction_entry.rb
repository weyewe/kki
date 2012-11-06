
=begin

  Transaction has many TransactionEntries -> (recording all money cash flow of the member)
    TransactionEntry can be in the form of 
          incoming payment (receiving money from member)  <- record all $$$ received from the member
            principal, 
            interest, 
            savings, 
            fine , 
            initial deposit,
            initial saving
          outgoing payment:
            returning the deposit to the member
            soft deposit takeout to pay using savings 
  
  With Transaction and TransactionEntry, we can record all the money flowing in, flowing out,
  and the field worker responsible for that. 
          
  Saving  has many SavingEntry 
    1. Debit to the savings account
    2. Soft withdrawal from savings account (using savings to pay)
    3. Hard withdrawal from savings account
          
  One TransactionActivity has many TransactionEntry 
  example, the member gives 50,000 rupiah to field worker
    it can be for 4 payments:
    1. 20,000 cash is the principal payment
    2. 5000 cash is the fine (late payment )
    3. 20,000 cash is for the savings payment 
    4. 5,0000 cash is for the interest payment
    
  But, it can only happen that one TransactionEntry contains less than 4 payments:
  example: not enough money (just 4000).  so, the member asked the worker to do: 
  Basic payment: 25k (20k == principal, 5k == interest)
  Transaction:
  1. Take 21k cash from savings account (saving credit)
  2. Pay 20k for principal
  3. Pay 5k for interest
  
  
  type of action can be done to savings account:
  1. Soft Withdraw to pay for loan
  2. Withdraw the $$$
  3. Hard Withdrawal 
  
  
  How can we model withdrawal from one's account 
  transaction_activity has_many transaction_entry
  transaction_entry has_one saving_entry 
  
  if we delete a transaction activity, the changes has to be propagated all the way to the saving entry
  
  up to now, we have just been considering the effect of transaction entry to the 
  member's savings. Why? Because the office's profit is handled outside the system. 
  
  What if we want it to be handled inside the system? the cashflow_book_entry book has to be changed as well (principal + interest payment)
=end


class TransactionEntry < ActiveRecord::Base
  belongs_to :transaction_book
  belongs_to :transaction_activity 
  
  belongs_to :cashflow_book_entry 
  
  has_one :saving_entry # if it is linked to the weekly_payment from member to office
  
  def delete
    self.is_deleted = true
    self.deleted_datetime = DateTime.now 
    self.save
    
    # revert the effect 
    case  self.transaction_entry_code
    when TRANSACTION_ENTRY_CODE[:weekly_saving]  # in 
      
    when TRANSACTION_ENTRY_CODE[:extra_weekly_saving] # in 
      member.deduct_compulsory_savings( self ) 
    when TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal]  # out 
      member.add_extra_savings( self )
    end
    
  end
  
  
  def revert_and_delete
    saving_entry  = self.saving_entry
    saving_book = saving_entry.saving_book 
    
    puts "777 te amount is #{self.amount.to_i}"
    case  self.transaction_entry_code
      
      
    when TRANSACTION_ENTRY_CODE[:weekly_saving]  # compulsory_savings  
      
      puts "777 deleting compulsory, #{self.amount.to_i}"
      puts "Saving book , compulsory savings before revert: #{saving_book.total_compulsory_savings.to_i}"
      saving_entry.is_deleted = true 
      saving_entry.save 
      
      saving_book.revert_transaction_deduct_compulsory_savings( self.amount ) 
      # saving_book = saving_entry.saving_book
      #     saving_book.total_compulsory_savings = saving_book.total_compulsory_savings - self.amount 
      #     saving_book.total = saving_book.total -  self.amount 
      #     saving_book.save  
      #     
      saving_book.reload
      puts "THe amount of FINAL compulsory savings  after revert is: #{saving_book.total_compulsory_savings}"
    when TRANSACTION_ENTRY_CODE[:extra_weekly_saving]   
      puts "777 deleting extra, #{self.amount.to_i}"
      saving_entry.is_deleted = true 
      saving_entry.save 
      
      
      saving_book.revert_transaction_deduct_extra_savings( self.amount ) 
    when   TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings]# in 
      puts "777 deleting extra, #{self.amount.to_i}"
      saving_entry.is_deleted = true 
      saving_entry.save 
    
      saving_book.revert_transaction_deduct_extra_savings( self.amount ) 
    when TRANSACTION_ENTRY_CODE[:only_savings_independent_payment]
      saving_entry.is_deleted = true 
      saving_entry.save 
    
      saving_book.revert_transaction_deduct_extra_savings( self.amount )
      
    when TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal]  # out 
      puts "777 adding extra, #{self.amount.to_i}"
      saving_entry.is_deleted = true 
      saving_entry.save 
      
      saving_book.revert_transaction_add_extra_savings( self.amount ) 
    end
    
    
    self.is_deleted = true
    self.deleted_datetime = DateTime.now 
    self.save
    
  end
end
