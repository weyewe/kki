class Saving < ActiveRecord::Base
  belongs_to :member
  has_many :payments 
end
