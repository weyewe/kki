
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
=end


class TransactionEntry < ActiveRecord::Base
  belongs_to :transaction_book
  belongs_to :transaction_activity 
  
  belongs_to :cashflow_book_entry 
  
end
