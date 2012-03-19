class SavingBook < ActiveRecord::Base
  belongs_to :member
  has_many :saving_entries
end
