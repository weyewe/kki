class AddSubGroupUpdateTimeToGroupLoanMembership < ActiveRecord::Migration
  def change
    add_column :group_loan_memberships, :sub_group_update_datetime, :datetime 
  end
end
