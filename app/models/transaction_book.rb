=begin
   Each member has its transaction book
   From this transaction book, we will know the net worth of that member to KKI 
    and all other calculations that we haven't known for now 
=end
class TransactionBook < ActiveRecord::Base
  belongs_to :member 
  has_many :transaction_entries
end
