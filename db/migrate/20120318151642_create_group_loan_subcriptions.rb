class CreateGroupLoanSubcriptions < ActiveRecord::Migration
  def change
    create_table :group_loan_subcriptions do |t|
      t.integer :group_loan_membership_id 
      t.integer :group_loan_product_id

      t.timestamps
    end
  end
end
