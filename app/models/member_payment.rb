class MemberPayment < ActiveRecord::Base
  belongs_to :weekly_task
  # there is no belongs_to :transaction_activity
  # because 1 transaction activity can have 1 member payment, or many.. 
  # remember, the member can make multiple payment 
  
  def transaction_activity
    TransactionActivity.find_by_id self.transaction_activity_id
  end
end
