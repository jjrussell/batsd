require 'spec_helper'

describe GamerReview do
  subject { Factory(:gamer_review) }

  context 'when associating' do
    it { should belong_to :author }
    it { should belong_to :app }
  end

  context 'when validating' do
    it { should validate_presence_of :author }
    it { should validate_presence_of :app }
    it { should validate_presence_of :text }
  end

  context 'when delegating' do
    it "delegates app_name and app_id to app" do
      delegated_methods = [ :app_name, :app_id ]
      delegated_methods.each do |dm|
        subject.should respond_to dm
      end
    end

    it "delegates get_gamer_name to author" do
      delegated_methods = [ :get_gamer_name ]
      delegated_methods.each do |dm|
        subject.should respond_to dm
      end
    end
  end

  context '#update_app_rating_counts' do
    before :each do
      subject.prev_rating = subject.user_rating
    end

    context 'when user_rating changed' do
      before :each do
        subject.user_rating = -1
        subject.save
        subject.reload
      end

      it 'decreases the app thumb_up_count' do
        subject.app.thumb_up_count.should == 0
      end

      it 'increases the app thumb_down_count' do
        subject.app.thumb_down_count.should == 1
      end
    end
  end
end
