class SubGroup < ActiveRecord::Base
  has_many :group_loan_memberships 
  belongs_to :group_loan 
end
