class GroupLoanSubcription < ActiveRecord::Base
  belongs_to :group_loan
  belongs_to :member
end
