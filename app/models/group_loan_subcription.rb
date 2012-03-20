class GroupLoanSubcription < ActiveRecord::Base
  belongs_to :group_loan_product 
  belongs_to :group_loan_membership
  
  
  def self.create_subcription( creator, group_loan_membership, group_loan_product )
    group_loan = group_loan_membership.group_loan 
    group_loan_subcription = GroupLoanSubcription.find(:first, :conditions => {
      :group_loan_membership_id => group_loan_membership.id,
      :group_loan_product_id => group_loan_product.id
    })
    
     # business logic , the loan_subscription can't be changed if the group_loan is running 
    if group_loan.is_started == true
      return group_loan_subcription  
    end
    
    if not group_loan_subcription.nil?
       group_loan_subcription.destroy 
     end
    
    new_group_loan_subcription = GroupLoanSubcription.create(
      :group_loan_membership_id => group_loan_membership.id,
      :group_loan_product_id => group_loan_product.id
    )
    # put the user activity list on who the creator is 
  end
end
