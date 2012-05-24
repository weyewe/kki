class CreateGroupLoanAssignments < ActiveRecord::Migration
  def change
    create_table :group_loan_assignments do |t|
      t.integer :user_id
      t.integer :group_loan_id
      t.integer :assignment_type , :default => GROUP_LOAN_ASSIGNMENT[:field_worker]

      t.timestamps
    end
  end
end
