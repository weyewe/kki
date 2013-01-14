=begin
Saving Book is used to handle Loan Product => group loan or personal loan 

It is clearly not a good way to name the Model. However, the software did evolved, following
the business evolution.

History:
1. Initially this software is used only for recording group loan, to help microfinance
2. As the microfinance progressed, it is found that the poor are responding to savings. However, 
no bank product that can cater to their need. 

3. Hence, we upgrade the software to handle savings account like those in the bank (with monthly interest rate)

4. The model used to handle normal savings account => SavingAccount , the entries: SavingAccountEntry
=end

class SavingBook < ActiveRecord::Base
  belongs_to :member
  has_many :saving_entries
  
  def revert_transaction_add_extra_savings(amount)
    self.total_extra_savings += amount
    self.total += amount
    self.save
  end
  
  def revert_transaction_deduct_extra_savings(amount)
    self.total_extra_savings -= amount
    self.total -= amount
    self.save
  end
  
  def revert_transaction_deduct_compulsory_savings(amount)
    self.total_compulsory_savings -= amount
    self.total -= amount
    self.save
  end
  
  def update_total(saving_entry, is_extra_savings)
    total_amount = self.total
    total_compulsory_savings = self.total_compulsory_savings
    total_extra_savings = self.total_extra_savings
    
    if saving_entry.saving_action_type == SAVING_ACTION_TYPE[:debit]
      total_amount += saving_entry.amount 
      if is_extra_savings == true
        total_extra_savings += saving_entry.amount
      elsif is_extra_savings == false
        total_compulsory_savings += saving_entry.amount
      end
    elsif saving_entry.saving_action_type == SAVING_ACTION_TYPE[:credit]
      total_amount -= saving_entry.amount
      
      if is_extra_savings
        total_extra_savings -= saving_entry.amount
      else
        total_compulsory_savings -= saving_entry.amount
      end
    end
    
    self.total = total_amount
    self.total_compulsory_savings = total_compulsory_savings
    self.total_extra_savings = total_extra_savings
    self.save
    
    saving_entry.saving_book_id = self.id
    saving_entry.save 
  end
  
=begin
  SAVINGS_ACCOUNT
=end
  
  def update_total_savings_account( saving_entry) 
    # ensure that this shite is indeed savings account 
    return nil if saving_entry.savings_case != SAVING_CASE[:savings_account] 
    
    total_amount = self.total_savings_account 
    
    if saving_entry.saving_action_type == SAVING_ACTION_TYPE[:debit]
      total_amount += saving_entry.amount  
    elsif saving_entry.saving_action_type == SAVING_ACTION_TYPE[:credit]
      total_amount -= saving_entry.amount
    end
    
    self.total_savings_account = total_amount 
    self.save
    saving_entry.saving_book_id = self.id
    saving_entry.save
  end
  
  # start date is the lower limit of interest-deposit. example : 15 of last month
  # end date is the upper limit of interest deposit, example: 15 of this month
=begin

  check this out (graph). x axis == time
                          y axis = amount of total savings account which 
                                  monthly interest will be calculated


          --------                  
                                  -------------------  
  --------                    
                  ----------------  
  t1  t2          t3              t4                t5                         
  ================================== 
=end
  def self.generate_savings_account_interest(member, start_date, end_date, annual_interest_rate )
    savings_account_array = []
    current_total_savings_account = member.saving_book.total_savings_account
    # setup base data to re-create the savings_account groph
    end_period = end_date
    start_period = start_date 
    
    # building the graph data point 
  
    SavingEntry.where(
      :member_id => member.id , 
      :is_interest_charged => false , 
      :savings_case =>  SAVING_CASE[:savings_account],
      :date => start_date..end_date 
    ).order("created_at DESC").each do |saving_entry|
      amount = BigDecimal('0')
      end_period = ''
      start_period = '' 
      
      if saving_entry.saving_action_type == SAVING_ACTION_TYPE[:debit]
        current_total_savings_account -= saving_entry.amount
      elsif saving_entry.saving_action_type == SAVING_ACTION_TYPE[:credit]
        current_total_savings_account += saving_entry.amount
      end
      
      if saving_entry.created_at.to_date > start_date
        start_period = saving_entry.created_at.to_date
      else
        start_period = start_date
      end
      
      savings_account_array << {
        :amount => current_total_savings_account,
        :start_date => start_period ,
        :end_date => end_date
      }
      
      # update the end date
      if start_period > start_date 
        end_period  = start_period
      else
        end_period = start_date 
      end
      
      saving_entry.is_interest_charged = true
      saving_entry.save 
    end # end of building graph data point 
    
    # calculating the interest 
    total_interest = BigDecimal("0")
    total_days_in_period = end_date - start_date 
    monthly_interest_rate = annual_interest_rate/12.to_f
    pro_rated_days = period_duration/total_days_in_period.to_f
    
    savings_account_array.each do |interest_period|
      period_duration = interest_period[:end_date] - interest_period[:start_date]
      total_interest += interest_period[:amount]*
                        ( 1 + monthly_interest_rate )*
                        pro_rated_days
    end
    
    # create interest entry 
    
    TransactionActivity.add_monthly_interest_savings_account(   member, total_interest ) 
    
    
  end
end
