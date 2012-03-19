=begin
  Records important timeline 
  such as:
  Branch Manager creates a new group loan product 
  
  1. Loan Officer asks approval for the group loan
  2. Branch Manager rejects  / approves 
  3. All deposit and initial savings has been received by the cashier 
  4. Weekly payments has been received by the cashier, and the total amount for the group is correct
  5.All the weekly payment has been paid, and the company is subjected to returning the deposit 
  6. BranchManager approved the deposit return
  7. All the deposit has been returned by the cashier 
  DEFAULT CASE
  8. The 52 weeks has passed, and there are some default. The payment for default will be taken from initial deposit
    -> Show the calculation for BranchManager To Approve 
  9. 
  
  6. Some clients defaulted on the payment 
=end

class TimelineActivity < ActiveRecord::Base
end
