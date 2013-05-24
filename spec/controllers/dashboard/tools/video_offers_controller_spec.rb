require 'spec_helper'

describe Dashboard::Tools::VideoOffersController do
  before :each do
    activate_authlogic
    login_as(user)


    @controller.stub(:log_activity)
  end

  let(:user) { FactoryGirl.create(:admin) }
  let(:partner) { FactoryGirl.create(:partner) }
  let(:video_offer) { FactoryGirl.create(:video_offer) }

  describe '#new' do
    it 'shows the new video offer form' do
      get(:new, :partner_id => partner.id)

      response.should be_success
    end
  end

  describe '#edit' do
    it 'shows the edit form' do
      get(:edit, :id => video_offer)

      response.should be_success
    end
  end

  describe '#create' do

    before :each do
      @video_offer = double(:id => 21)
      VideoOffer.should_receive(:new).
        with("primary_offer_creation_attributes" => {}).and_return(@video_offer)
    end

    let(:params) { { :video_offer => {
      :primary_offer_attributes => {}
      }}
    }

    it 'fails validation' do
      @video_offer.should_receive(:save).and_return(false)
      @video_offer.should_receive(:build_primary_offer)

      post(:create, params)

      response.should render_template("new")
    end

    it 'passes validation' do
      @video_offer.should_receive(:save).and_return(true)

      post(:create, params)

      response.should redirect_to(edit_tools_video_offer_path(@video_offer.id))
    end
  end

  describe "#update" do
    before :each do
      @video_offer = double(:id => 21, :primary_offer => 20)
      VideoOffer.stub(:find).
        with(@video_offer.id, :include => :partner).
        and_return(@video_offer)
    end

    it  'fails validation' do
      @video_offer.should_receive(:update_attributes).and_return(false)

      post(:update, :id => @video_offer.id)

      response.should render_template("edit")
    end

    it 'passes validation' do
      @video_offer.should_receive(:update_attributes).and_return(true)

      post(:update, :id => @video_offer.id)

      response.should redirect_to(statz_path(@video_offer.primary_offer))
    end

  end
end
