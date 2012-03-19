class Member < ActiveRecord::Base
  has_many :group_loans, :through => :group_loan_memberships
  has_many :group_loan_memberships
  
  # saving_book will list all the record of the member's saving 
  has_one :saving_book
  # transaction_book will list all the record of member's transaction 
  has_one :transaction_book


  belongs_to :office 
  
end
