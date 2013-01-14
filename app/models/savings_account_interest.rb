class SavingsAccountInterest < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  
  
  
   
  def start_interest_disbursement(employee)
    
    self.is_started = true 
    self.save 
    
    self.execute_interest_disbursement
  end
  
  def execute_interest_disbursement 
    return nil if not self.is_started? 
    return nil if self.is_finished? 
    # on the day 15 
    # use background job 
    this_month = self.created_at 
    last_month = self.created_at - 1.month 
    
    
    
    # it is run on 15th of this month, interest period => 15th last month to 14 this month
    end_date = Date.new( this_month.year, this_month.month, INTEREST_DAY_OF_THE_MONTH-1   ) 
    
    return nil if DateTime.now.to_date < end_date
    start_date = Date.new( last_month.year, last_month.month, INTEREST_DAY_OF_THE_MONTH-1  ) 
    
    
    
    # start_date =  
     
    office.members.each do |member|
      SavingBook.generate_savings_account_interest(member, 
                  start_date, 
                  end_date, 
                  self.annual_interest_rate )
    end 
    
    self.is_finished = true 
    self.save 
  end
  
  
  
end
