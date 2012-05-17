require 'spec_helper'

describe AppReview do
  subject { Factory(:gamer_review) }

  describe '.belongs_to' do
    it { should belong_to :author }
    it { should belong_to :app_metadata }
  end

  describe '#valid?' do
    it { should validate_presence_of :author }
    it { should validate_presence_of :app_metadata }
  end

  describe '.delegate' do
    it "delegates app_metadata_name to app_metadata" do
      delegated_methods = [ :app_metadata_name ]
      delegated_methods.each do |dm|
        subject.should respond_to dm
      end
    end
  end

  before :each do
    @gamer = Factory(:gamer)
    @gamer_review = Factory(:gamer_review, :author => @gamer)
  end

  describe '#update_app_metadata_rating_counts' do
    context 'when user_rating changed' do
      before :each do
        @gamer_review.user_rating = -1
        @gamer_review.save
        @gamer_review.reload
      end

      it 'decreases the app thumbs_up' do
        @gamer_review.app_metadata.thumbs_up.should == 0
      end

      it 'increases the app thumbs_down' do
        @gamer_review.app_metadata.thumbs_down.should == 1
      end
    end
  end

  describe '#author_name' do
    context 'when author_type is Gamer' do
      it 'returns gamer name' do
        @gamer_review.author_name.should == @gamer.get_gamer_nickname
      end
    end

    context 'when author_type is Employee' do
      before :each do
        @employee = Factory(:employee)
        @employee_review = Factory(:gamer_review, :author => @employee)
      end
      it 'returns employee name' do
        @employee_review.author_name.should == @employee.full_name
      end
    end
  end
end
