require 'spec_helper'

describe GroupLoan do
  
  context "group loan creation" do
    it "must be created by loan officer"
    it "geographical scope must be bound to the same commune (RW)"
  end
  
  context "group loan membership assignment" do 
    it "will only accept member whose commune is the same with this group loan's commune" 
    it "should not accept member with another on going group loan" 
  end
  
  context "group loan process" do
    # it "can only create member whose address is in this office's subdistrict"
  end
end