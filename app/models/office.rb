class Office < ActiveRecord::Base
  # The employee can move around offices
  # It is even possible for an employee to be registered in 2 offices 
  has_many :users, :through => :job_attachments 
  has_many :job_attachments 
  
  # The group loan created will be specific to the office
  # where the branch manager is attached at    -> GroupLoan is the product 
  has_many :group_loan_products
  has_one :cashflow_book
  
  # Groups is collection of members, each member is having one group loan 
  has_many :groups
  # members are registered to the office. Will only change when they move house
  has_many :members 
  
  
  has_many :transaction_activities 
  
  # Normally, 1 Office represents 1 Subdistrict  
  has_many :subdistricts, :through => :geo_scopes
  has_many :geo_scopes
end
