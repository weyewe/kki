class GroupLoanProduct < ActiveRecord::Base
  belongs_to :office 
  
  
  # has_many :group_loan_subscriptions
  #  has_many :group_loan_memberships, :through => :group_loan_subscriptions
  
  validates_presence_of :principal, :interest, :min_savings, :admin_fee, :initial_savings, :total_weeks
  validates_numericality_of :principal, :interest, :min_savings, :admin_fee, :initial_savings, :total_weeks
  
  
=begin
  Association methods 
=end
  
  def group_loan_subcriptions
    GroupLoanSubcription.find(:all, :conditions => {
      :group_loan_product_id => self.id 
    })
  end
  
  def group_loan_memberships
        # 
        # Client.joins(:orders).where(:orders => {:created_at => time_range})
        # 
        # 
    GroupLoanMembership.joins(:group_loan_subcription).where(
      :group_loan_subcription => { :group_loan_product_id => self.id }
    )
  end


  def grace_period_weekly_payment
    principal + interest 
  end
  
  
  def total_weekly_payment
    principal + interest + min_savings
  end
  
  def loan_amount
    principal*total_weeks
  end
  
  def interest_amount
    interest*total_weeks
  end
  
  def interest_rate
    interest/principal 
  end
  
  def interest_rate_in_percent
    interest_rate * 100 
  end
  
  def setup_payment_amount
    self.admin_fee + self.initial_savings 
  end
  
  def loan_amount_deducted_by_setup_amount
    loan_amount - setup_payment_amount 
  end
  
  
end
