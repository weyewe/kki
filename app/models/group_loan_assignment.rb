class GroupLoanAssignment < ActiveRecord::Base
  
  def self.add_new_assignment(task_symbol ,  group_loan,  user )
    GroupLoanAssignment.create(:assignment_type => GROUP_LOAN_ASSIGNMENT[task_symbol] ,
      :user_id => user.id, :group_loan_id => group_loan.id  )
  end
  
  def self.get_field_workers_for(group_loan)
    self.find(:all, :conditions => {
      :group_loan_id => group_loan.id,
      :assignment_type =>  GROUP_LOAN_ASSIGNMENT[:field_worker]
    })
  end
  
  def self.get_loan_inspectors_for(group_loan)
    self.find(:all, :conditions => {
      :group_loan_id => group_loan.id,
      :assignment_type =>  GROUP_LOAN_ASSIGNMENT[:loan_inspector]
    })
  end
end
