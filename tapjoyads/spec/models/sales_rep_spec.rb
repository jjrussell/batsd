require 'spec_helper'

describe SalesRep do

  describe '.belongs_to' do
    it { should belong_to :offer }
    it { should belong_to :sales_rep }
  end

  describe '#valid?' do
    it { should validate_presence_of :offer_id }
    it { should validate_presence_of :sales_rep_id }
    it { should validate_presence_of :start_date }
    it { should_not validate_presence_of :end_date }
    it 'is invalid when the start date is after the end date' do
      subject.start_date = Date.today
      subject.end_date = Date.yesterday
      subject.should_not be_valid
      subject.errors[:start_date].join.should == "Start date cannot be after end date"
    end
  end

end
