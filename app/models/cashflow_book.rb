class CashflowBook < ActiveRecord::Base
  belongs_to :office
  has_many :cashflow_book_entries 
end
