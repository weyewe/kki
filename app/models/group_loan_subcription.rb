class GroupLoanSubcription < ActiveRecord::Base
  belongs_to :group_loan_product 
  belongs_to :group_loan_membership
end
