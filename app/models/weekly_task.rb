class WeeklyTask < ActiveRecord::Base
  has_many :member_payments
  has_many :member_attendances 
end
