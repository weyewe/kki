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
  
  
  def self.create_or_change( group_loan_product_id , group_loan_membership_id  )
    
    group_loan_membership = GroupLoanMembership.find_by_id group_loan_membership_id
    
    if group_loan_membership.nil?
      # bad data 
      return nil
    end
    
    group_loan = group_loan_membership.group_loan
    group_loan_subcription = group_loan_membership.group_loan_subcription 
    new_group_loan_subcription = ''
    # business logic.. if the group loan has started, nobody can change the group_loan_product 
    if group_loan.is_started == true 
      # is there any case where a member hasn't been assigned loan, but the group loan is_started == true?
      # ans => can't happen. To activate is_started == true, all member has a group loan product 
      return group_loan_subcription
    end
    
    if not group_loan_subcription.nil?
      # update case 
      group_loan_subcription.group_loan_product_id = group_loan_product_id
      group_loan_subcription.save 
    else
      # create case 
      group_loan_subcription = GroupLoanSubcription.create(
        :group_loan_membership_id => group_loan_membership_id, 
        :group_loan_product_id => group_loan_product_id
      )
    end
    
    return group_loan_subcription
  end
end
