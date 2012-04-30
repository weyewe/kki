class DefaultPayment < ActiveRecord::Base
  belongs_to :group_loan_membership 
end
