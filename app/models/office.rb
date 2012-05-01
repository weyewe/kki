class Office < ActiveRecord::Base
  # The employee can move around offices
  # It is even possible for an employee to be registered in 2 offices 
  has_many :users, :through => :job_attachments 
  has_many :job_attachments 
  
  # The group loan created will be specific to the office
  # where the branch manager is attached at    -> GroupLoan is the product 
  has_many :group_loan_products
  has_one :cashflow_book
  
  # Groups is collection of members, each member is having one group loan 
  has_many :group_loans
  # members are registered to the office. Will only change when they move house
  has_many :members 
  
  
  has_many :transaction_activities 
  
  # Normally, 1 Office represents 1 Subdistrict  
  has_many :subdistricts, :through => :geo_scopes
  has_many :geo_scopes
  
  
  after_create :create_cashflow_book
  
  def all_communes_under_management
    subdistricts = self.subdistricts.includes(:villages => [:communes] ) 
    puts "good with subdistricts"
    result = []
    subdistricts.each do |subdistrict|
      subdistrict.villages.each do |village| 
        village.communes.each do |commune|
          result << [ "#{subdistrict.name}, #{village.name} -- RW #{commune.number }" , 
                          commune.id ]
        end
      end
    end
    return result 
  end
  
  
  # active means still pending for action
  def active_group_loans
    self.group_loans.where(:is_closed => false )
  end
  
  def pending_approval_group_loans
    self.group_loans.where(:is_closed => false , :is_proposed => true , :is_started => false )
  end
  
  def pending_setup_collection_group_loans
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true,
                :is_setup_fee_collection_finalized => true , 
                :is_setup_fee_collection_approved => false  )
  end
  
  def disbursable_group_loans
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true,
                :is_setup_fee_collection_finalized => true , 
                :is_setup_fee_collection_approved => true , 
                :is_loan_disbursement_done => false  )
  end
  
  def running_group_loans
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true,
                :is_setup_fee_collection_finalized => true , 
                :is_setup_fee_collection_approved => true , 
                :is_loan_disbursement_done => true, 
                :is_closed => false,
                :is_group_loan_default => false   )
  end
  
  
  
  
  def default_declarable_group_loans
    valid_running_group_loans = self.running_group_loans
    group_loans_array = []
    valid_running_group_loans.each do |group_loan|
      if group_loan.completed_weekly_tasks.count == group_loan.total_loan_duration
        group_loans_array << group_loan 
      end
    end
    return group_loans_array 
  end
  
  
  
  # it is runnning.. can't be changed anymore 
  def started_group_loans
    self.group_loans.where(:is_started => true , :is_closed => false )
  end
  
  # done.. loan duration has finished, either end up in the default or not 
  def closed_group_loans
    self.group_loans.where(:is_started => true , :is_closed => true )
  end
  
=begin
  TransactionActivity reporting 
=end
  
  def loan_disbursement_transaction_activities
    TransactionActivity.find(:all, :conditions => {
      :office_id => self.id ,
      :transaction_case => TRANSACTION_CASE[:loan_disbursement]
    })
  end
  
  protected
  def create_cashflow_book
    # self.cashflow_book.create 
    CashflowBook.create :office_id => self.id
  end
  
end
