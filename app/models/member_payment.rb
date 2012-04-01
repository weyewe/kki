class MemberPayment < ActiveRecord::Base
  belongs_to :weekly_task
  
  def transaction_activity
    TransactionActivity.find_by_id self.transaction_activity_id
  end
end
