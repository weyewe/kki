class CashflowBookEntry < ActiveRecord::Base
  belongs_to :cashflow_book
  has_one :transaction_entry 
end
