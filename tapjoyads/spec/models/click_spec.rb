require 'spec_helper'

describe Click do
  before :each do
    @click = FactoryGirl.create(:click)
  end
  
  describe "#url_to_resolve" do
    context "when generic click" do
      before :each do
        @click.type = 'generic'
      end

      it "creates a url that goes to offer_completed controller" do
        expected = "#{API_URL}/offer_completed?click_key=#{@click.key}"
        @click.send(:url_to_resolve).should == expected
      end
    end
    context "when not generic click" do
      before :each do
        @click.type = 'featured_install'
      end

      it "creates a connect call url" do
        expected = "#{API_URL}/connect?app_id=#{@click.advertiser_app_id}&udid=#{@click.udid}&consistent=true"
        @click.send(:url_to_resolve).should == expected
      end
    end
  end

  describe '#dashboard_device_info_tool_url' do
    include Rails.application.routes.url_helpers
    
    it 'matches URL for Rails device_info_tools_url helper' do
      @click.dashboard_device_info_tool_url.should == "#{URI.parse(DASHBOARD_URL).scheme}://#{URI.parse(DASHBOARD_URL).host}/tools/device_info?click_key=#{@click.key}"
    end
  end

  describe '#update_partner_live_dates' do
    before :each do
      @stamp = Time.zone.now
      @click.clicked_at = @stamp
      @publisher = FactoryGirl.create(:partner)
      @click.publisher_amount = 10
      @publisher.save!
      @click.publisher_partner_id = @publisher.id

      @advertiser = FactoryGirl.create(:partner)
      @click.advertiser_amount = 20
      @advertiser.save!
      @click.advertiser_partner_id = @advertiser.id
    end

    it 'updates the live date for the publisher' do
      @click.update_partner_live_dates!
      @publisher.reload
      @publisher.live_date.to_s.should == @stamp.to_s
    end

    it 'updates the live date for the advertiser' do
      @click.update_partner_live_dates!
      @advertiser.reload
      @advertiser.live_date.to_s.should == @stamp.to_s
    end
  end

  describe '#save' do
    context 'when publisher_app_id changes' do
     context 'publisher_app_id not initially set' do
        it 'will do nothing extra' do
          @click.stub(:publisher_app_id_was).and_return(nil)
          @click.publisher_app_id = 'test'
          @click.save
          @click.previous_publisher_ids.should be_empty
        end
      end
      context 'publisher_app_id set initially' do
        it 'will save the previous id' do
          @click.save
          expected_array = []
          expected_array << { 'publisher_app_id' => @click.publisher_app_id,
                              'updated_at' => @click.updated_at.to_f,
                              'publisher_user_id' => @click.publisher_user_id
                            }
          @click.publisher_app_id = 'new1'
          @click.save
          @click.previous_publisher_ids.should == expected_array
        end
      end
    end

    context 'when publisher_app_id does not change' do
      it 'will do nothing extra' do
        @click.save
        @click.advertiser_amount = 20
        @click.save
        @click.previous_publisher_ids.should be_empty
      end
    end
  end
end
