require 'spec_helper'

describe ActionOffer do
  subject { FactoryGirl.create :action_offer }
  it { should have_many :offers }
  it { should have_one :primary_offer }
  it { should belong_to :partner }
  it { should belong_to :app }

  it { should validate_presence_of :partner }
  it { should validate_presence_of :app }
  it { should validate_presence_of :instructions }
  it { should validate_numericality_of :price }

  it 'accepts nested attributes for primary_offer' do
    subject.should respond_to(:primary_offer_attributes=)
  end

  it 'delegates user_enabled?, tapjoy_enabled?, bid, min_bid, and daily_budget to primary_offer' do
    delegated_methods = [ :user_enabled?, :tapjoy_enabled?, :bid, :min_bid, :daily_budget ]
    delegated_methods.each do |dm|
      subject.should respond_to dm
    end
  end

  context 'on creation with non-live app' do
    it 'creates primary offer with no app metadata association' do
      @app = FactoryGirl.create(:non_live_app, :platform => 'android')
      action_offer = FactoryGirl.create(:action_offer, :app => @app)
      action_offer.offers.count.should == 1
      action_offer.primary_offer.should_not be_nil
      action_offer.primary_offer.app_metadata.should be_nil
    end
  end

  context 'on creation' do
    before :each do
      @app = FactoryGirl.create(:app, :platform => 'android')
    end

    context 'with app having one active distribution' do
      it 'creates primary offer with app metadata association' do
        action_offer = FactoryGirl.create(:action_offer, :app => @app)
        action_offer.offers.count.should == 1
        action_offer.primary_offer.should_not be_nil
        action_offer.primary_offer.app_metadata.should == @app.primary_app_metadata
      end
    end

    context 'with app having multiple active distributions' do
      it 'creates one primary offer and secondary offers' do
        secondary_metadata = @app.add_app_metadata('android.GFan', 'xyz123')
        secondary_metadata.should_not be_nil
        action_offer = FactoryGirl.create(:action_offer, :app => @app)
        action_offer.offers.count.should == 2
        action_offer.primary_offer.should_not be_nil
        action_offer.primary_offer.app_metadata.should == @app.primary_app_metadata
        action_offer.offers.find_by_app_metadata_id(secondary_metadata.id).should_not be_nil
      end
    end
  end

  context 'when updated' do
    it 'updates its associated Offers' do
      subject.update_attributes(:name => 'this is a new name')
      subject.offers.each do |offer|
        offer.name.should == "this is a new name"
      end
    end

    it 'updates its associated offers instructions' do
      subject.update_attributes(:instructions => 'take a flying leap!')
      subject.offers.each do |offer|
        offer.instructions.should == "take a flying leap!"
      end
    end

    context 'and instructions are overridden' do
      before :each do
        subject.offers.first.update_attributes(:instructions_overridden => true, :instructions => 'just for this one')
      end

      it "doesn't update associated offer instructions" do
        subject.update_attributes(:instructions => 'take a flying leap!')
        subject.offers.first.instructions.should == 'just for this one'
      end
    end
  end

  context 'pricing' do
    before :each do
      @app = FactoryGirl.create(:app, :platform => 'android')
    end

    context 'when has prerequisite offer' do
      it 'sets associated offer price to action offer price' do
        @app.primary_app_metadata.update_attributes(:price => 125)
        action_offer = FactoryGirl.create(:action_offer, :app => @app, :price => 250, :prerequisite_offer => @app.primary_offer)
        action_offer.primary_offer.price.should == action_offer.price
      end
    end

    context 'when no prerequisite offer and app metadata is paid' do
      it 'sets associated offer price to action offer price plus metadata price' do
        @app.primary_app_metadata.update_attributes(:price => 125)
        action_offer = FactoryGirl.create(:action_offer, :app => @app, :price => 250)
        action_offer.primary_offer.price.should == action_offer.price + @app.primary_app_metadata.price
      end
    end

    context 'when no prerequisite offer and app metadata is free' do
      it 'sets associated offer price to action offer price' do
        action_offer = FactoryGirl.create(:action_offer, :app => @app, :price => 250)
        action_offer.primary_offer.price.should == action_offer.price
      end
    end
  end

  context 'when app metadata is added' do
    before :each do
      @app = FactoryGirl.create(:app, :platform => 'android')
      @action_offer = FactoryGirl.create(:action_offer, :app => @app)
      @action_offer.offers.count.should == 1
    end

    it 'adds a new ActionOffer' do
      secondary_metadata = @app.add_app_metadata('android.GFan', 'xyz123')
      secondary_metadata.should_not be_nil
      @action_offer.reload
      @action_offer.offers.count.should == 2
      @action_offer.offers.find_by_app_metadata_id(secondary_metadata.id).should_not be_nil
    end
  end

  context 'when non-live app is made live after action offer was created' do
    before :each do
      @app = FactoryGirl.create(:non_live_app, :platform => 'android')
      @action_offer = FactoryGirl.create(:action_offer, :app => @app)
      @primary_action_offer = @action_offer.primary_offer
      @primary_action_offer.should_not be_nil
      @primary_action_offer.app_metadata.should be_nil
    end

    it 'updates action offer with new primary metadata' do
      @app.add_app_metadata('android.GFan', 'xyz123', true)
      @app.reload
      @primary_action_offer.reload
      @primary_action_offer.app_metadata.should_not be_nil
      @primary_action_offer.app_metadata.should == @app.primary_app_metadata
    end
  end

  context 'when app metadata is updated to a new store id' do
    before :each do
      @app = FactoryGirl.create(:app, :platform => 'android')
      @action_offer = FactoryGirl.create(:action_offer, :app => @app)
      @metadata = FactoryGirl.create(:app_metadata,
        :store_name => @app.primary_app_metadata.store_name,
        :store_id   => 'abc321',
        :name       => 'MyFavoriteApp',
        :price      => 399 )
    end

    it 'updates the ActionOffer' do
      @app.update_app_metadata(@app.primary_app_metadata.store_name, 'abc321')
      @action_offer.reload
      @action_offer.primary_offer.app_metadata == @metadata
      @action_offer.primary_offer.url.should == @metadata.store_url
      @action_offer.primary_offer.price.should == 399
      @action_offer.primary_offer.name.should_not == 'MyFavoriteApp'
      @action_offer.primary_offer.name.should == @action_offer.name
    end
  end

  context 'when app metadata is updated' do
    before :each do
      @app = FactoryGirl.create(:app, :platform => 'android')
      @action_offer = FactoryGirl.create(:action_offer, :app => @app)
      @secondary_metadata = @app.add_app_metadata('android.GFan', 'xyz123')
    end

    it 'updates the ActionOffer' do
      @secondary_metadata.update_attributes(:name => 'name should not be updated', :price => 1000)
      @action_offer.reload
      @action_offer.offers.find_by_app_metadata_id(@secondary_metadata.id).price.should == 1000
      @action_offer.offers.find_by_app_metadata_id(@secondary_metadata.id).name.should_not == 'name should not be updated'
      @action_offer.offers.find_by_app_metadata_id(@secondary_metadata.id).name.should == @action_offer.name
    end
  end

  context 'when app metadata is removed' do
    before :each do
      @app = FactoryGirl.create(:app, :platform => 'android')
      @action_offer1 = FactoryGirl.create(:action_offer, :app => @app)
      @action_offer2 = FactoryGirl.create(:action_offer, :app => @app, :name => 'do something else')
      @secondary_metadata = @app.add_app_metadata('android.GFan', 'xyz123')
    end

    it 'destroys associated ActionOffers' do
      @action_offer1.offers.find_by_app_metadata_id(@secondary_metadata.id).should_not be_nil
      @action_offer2.offers.find_by_app_metadata_id(@secondary_metadata.id).should_not be_nil
      @app.remove_app_metadata(@secondary_metadata)
      @action_offer1.offers.find_by_app_metadata_id(@secondary_metadata.id).should be_nil
      @action_offer2.offers.find_by_app_metadata_id(@secondary_metadata.id).should be_nil
    end
  end
end
