class TransactionActivity < ActiveRecord::Base
  has_many :transaction_entries 
  belongs_to :office 
end
