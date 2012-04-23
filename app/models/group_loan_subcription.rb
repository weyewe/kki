class GroupLoanSubcription < ActiveRecord::Base
  belongs_to :group_loan_product 
  belongs_to :group_loan_membership
  
  
  
  
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
      # puts "3353 in the not nil block\n"*2
      old_group_loan_product_id = group_loan_subcription.group_loan_product_id
      new_group_loan_product_id = group_loan_product_id
      
      group_loan_subcription.group_loan_product_id = new_group_loan_product_id
      group_loan_subcription.save 
      group_loan.change_group_loan_subcription( new_group_loan_product_id , old_group_loan_product_id) 
    else
      # create case 
       puts "434 in the create case block\n"*2
      group_loan_subcription = GroupLoanSubcription.create(
        :group_loan_membership_id => group_loan_membership_id, 
        :group_loan_product_id => group_loan_product_id
      )
      puts "after the create"
      group_loan.add_group_loan_subcription( group_loan_product_id )
    end
    
    return group_loan_subcription
  end
end
