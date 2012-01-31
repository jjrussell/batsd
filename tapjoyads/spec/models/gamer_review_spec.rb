require 'spec_helper'

describe GamerReview do
  before :each do
    @gamer_review = Factory(:gamer_review)
  end

  # subject { Factory(:gamer_review) }

  context 'when associating' do
    it { should belong_to :author }
    it { should belong_to :app }
  end

  context 'when validating' do
    # it 'has author' do
    #   @gamer_review.author.should be_present
    # end
    it { should validate_presence_of :author }
    it { should validate_presence_of :app }
    it { should validate_presence_of :text }
  end

  context 'when delegating' do
    it "delegates name to app" do
      delegated_methods = [ :name ]
      delegated_methods.each do |dm|
        @gamer_review.should respond_to dm
      end
    end
  
    it "delegates get_gamer_name to author" do
      delegated_methods = [ :get_gamer_name ]
      delegated_methods.each do |dm|
        @gamer_review.should respond_to dm
      end
    end
  end
end
