class Regency < ActiveRecord::Base
  belongs_to :province
  has_many :subdistricts
end
