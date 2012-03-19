class GroupLoanProduct < ActiveRecord::Base
  belongs_to :office 
  
  has_many :loan_subscriptions
  has_many :group_loan_memberships, :through => :loan_subscriptions
  validates_presence_of :principal, :interest, :min_savings, :admin_fee, :initial_savings, :total_weeks
  validates_numericality_of :principal, :interest, :min_savings, :admin_fee, :initial_savings, :total_weeks
  
  def total_weekly_payment
    principal + interest + min_savings
  end
  
  def loan_amount
    principal*total_weeks
  end
  
  def interest_rate
    interest/principal
  end
end
