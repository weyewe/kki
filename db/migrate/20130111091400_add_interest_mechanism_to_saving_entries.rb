class AddInterestMechanismToSavingEntries < ActiveRecord::Migration
  def change
    # only savings account that needs to be confirmed 
    # we don't need to check is_confirmed because it is handled by transaction_activity
    # add_column :saving_entries, :is_confirmed, :boolean, :default => false 
    add_column :saving_entries, :is_interest_charged, :boolean, :default => false 
    # all money flow will go through transaction activities.
    # saving will only be manifested if the transaction activity is confirmed
    add_column :saving_entries, :savings_case , :integer, :default => SAVING_CASE[:group_loan]
  end
end
