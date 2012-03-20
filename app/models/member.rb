class Member < ActiveRecord::Base
  has_many :group_loans, :through => :group_loan_memberships
  has_many :group_loan_memberships
  
  # saving_book will list all the record of the member's saving 
  has_one :saving_book
  # transaction_book will list all the record of member's transaction 
  has_one :transaction_book


  belongs_to :office 
  
  validates_presence_of :name, :id_card_no , :commune_id 
  
  validates :id_card_no, :uniqueness => { 
    :case_sensitive => false,
    :message => "Harus unik. Sudah ada member dengan no KTP ini." }
    
  # def commune_data
  #     @commune = Commune.find_by_id( self.commune_id )
  #     @village = Village.find_by_id( @commune. )
  #     "#{subdistrict.name}, #{village.name} -- RW #{self.commune.number }"
  #   end
  
  def past_group_loans

    member_id = self.id
    GroupLoanMembership.joins(:group_loan).where(
             { :member_id => member_id   } & 
             {:group_loan => {:is_started => true }} & 
             {:group_loan => {:is_closed => true }}
             ).count
  end
    # 
    # t.boolean  "is_closed",          :default => false
    # t.integer  "group_closer_id"
    # t.boolean  "is_started",         :default => false
    # 
  
    
    def current_assigned_group_loans
      member_id = self.id
      GroupLoanMembership.joins(:group_loan).where(
               { :member_id => member_id   } &  
               {:group_loan => {:is_closed => false }}
               ).count
    end
    
    def current_active_group_loans
      member_id = self.id
      GroupLoanMembership.joins(:group_loan).where(
               { :member_id => member_id   } &  
               {:group_loan => {:is_closed => false }} & 
               {:group_loan => {:is_started => true }} 
               ).count
    end
  
  
  def is_group_loan_member?(group_loan) 
    not GroupLoanMembership.find(:first, :conditions => {
      :member_id => self.id,
      :group_loan_id => group_loan.id 
    }).nil?
  end
  
  
  
end
