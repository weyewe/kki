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
  
  
  # regency : kabupaten ,several offices ? perhaps. best case 
  
  # Normally, 1 Office represents 1 Subdistrict  
  has_many :subdistricts, :through => :geo_scopes
  has_many :geo_scopes
  
  
  after_create :create_cashflow_book
  
=begin
  Office management
=end

  def create_user(role_list, user_hash)
    new_user = User.new(user_hash)
    
    if not new_user.save
      return nil
    end
    
    job_attachment = JobAttachment.create(:user_id => new_user.id, :office_id => self.id)
    
    role_list.each do |role|
      Assignment.create_role_assignment_if_not_exists( role,  new_user)
    end
    
    return new_user 
    
  end
  
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
  
  def started_group_loans 
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true)
  end
  
  def loan_disbursement_meeting_group_loans
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true,
                :is_financial_education_attendance_done => true)
  end
  
  def loan_disbursable_group_loans
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true,
                :is_financial_education_attendance_done => true,
                :loan_disbursement_finalization_proposed => true )
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
                :is_loan_disbursement_approved => false  )
  end
  
  def running_group_loans
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true,
                :is_setup_fee_collection_finalized => true , 
                :is_setup_fee_collection_approved => true , 
                :is_loan_disbursement_approved => true )
  end
  
  
  def group_loans_with_unapproved_grace_period_payment
    running_group_loans = self.group_loans.where(
      :is_proposed => true , 
      :is_started => true,
      :is_setup_fee_collection_finalized => true , 
      :is_setup_fee_collection_approved => true , 
      :is_loan_disbursement_approved => true )
  
    
    unapproved_grace_period_group_loan_list = [] 
    running_group_loans.each do |group_loan|
      if group_loan.pending_approval_grace_period_transactions.count != 0 
        unapproved_grace_period_group_loan_list << group_loan 
      end
    end
    
    return unapproved_grace_period_group_loan_list
  end
  
  def group_loans_for_default_resolution_execution
    self.group_loans.where(
                :is_proposed => true , 
                :is_started => true,
                :is_setup_fee_collection_finalized => true , 
                :is_setup_fee_collection_approved => true , 
                :is_loan_disbursement_approved => true, 
                :is_default_payment_resolution_proposed => true ,
                :is_default_payment_resolution_approved => [false,true],
                :is_closed => false  )
  end
  
  def default_declared_group_loans
    self.group_loans.where(
                :is_proposed => true , 
                :is_started => true,
                :is_setup_fee_collection_finalized => true , 
                :is_setup_fee_collection_approved => true , 
                :is_loan_disbursement_approved => true, 
                :is_closed => false,
                :is_group_loan_default => true   )
  end
  
  def closed_group_loans
    self.group_loans.where(:is_closed => false , 
                :is_proposed => true , 
                :is_started => true,
                :is_setup_fee_collection_finalized => true , 
                :is_setup_fee_collection_approved => true , 
                :is_loan_disbursement_approved => true, 
                :is_closed => true,
                :is_group_loan_default => true   )
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
