require 'spec_helper'

describe Member do
  it 'should create a transaction_book and saving_book after create' do
    member = Member.create :name => "Willy", :id_card_no  => "234232", :commune_id  => 1
    
    member.should be_valid
    member.saving_book.should be_valid
    member.transaction_book.should be_valid
  end
  
  context 'add savings' do
    before(:each) do
      @member = Member.create :name => "Willy", :id_card_no  => "234232", :commune_id  => 1
    end
    
    it "should create one saving_entry" do
      initial_total_savings = @member.total_savings
      
      savings_amount = BigDecimal("10000")
      saving_entry = @member.add_savings( savings_amount , SAVING_ENTRY_CODE[:weekly_saving_from_basic_payment] )
      
      # saving_entry.should_receive(:update_saving_book)
      saving_entry.should be_valid
      saving_entry.amount.should == savings_amount
    end
    
    it "should add the total in the saving_book"  do
      initial_total_savings = @member.total_savings
      @member.total_savings.should == BigDecimal("0")
      
      savings_amount = BigDecimal("10000")
      saving_entry = @member.add_savings( savings_amount , SAVING_ENTRY_CODE[:weekly_saving_from_basic_payment] )
      
      final_total_savings = @member.saving_book.total - initial_total_savings
      final_total_savings.should == savings_amount
    end
  end
end