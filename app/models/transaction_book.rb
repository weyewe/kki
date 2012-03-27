=begin
   Each member has its transaction book
   From this transaction book, we will know the net worth of that member to KKI 
    and all other calculations that we haven't known for now 
    
  Why don't we put an extra column in the transaction_activity? 
    In that case, we need to re-calculate all data for reporting. But, if the customer has their own
      transaction_book, the total net worth can be calculated as the data changes. 
    
=end
class TransactionBook < ActiveRecord::Base
  belongs_to :member 
  has_many :transaction_entries
end
