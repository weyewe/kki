class AddCancelToTransactionActivities < ActiveRecord::Migration
  def change
    add_column :transaction_activities, :is_canceled,  :boolean , :default => false # when the transaction is deemed to be non existant
    # the cancelation is done by branch manager
    
    # example? the field worker picked the wrong member for independent payment
    # nothing can be done. only savings can't be amounted to 0 
    # it has to be cancelled -> report to branch manager. please cancel 
    add_column :transaction_activities, :canceler_id,  :boolean , :default => false 
    add_column :transaction_activities, :canceled_datetime,  :datetime 
  end
end
