require 'spec/spec_helper'

describe Tools::FeaturedContentsController do
  before :each do
    activate_authlogic
    @admin = Factory(:admin)
    @partner = Factory(:partner, :id => TAPJOY_PARTNER_ID)
    @admin.partners << @partner
    login_as(@admin)
  end

  describe '#create' do
    before :each do
      @start_date = Time.zone.now - 1.day
      @end_date = Time.zone.now + 1.day

      @options = {
        :featured_content => {
          :featured_type => FeaturedContent::TYPES_MAP[FeaturedContent::STAFFPICK],
          :platforms     => %w( iphone ipad itouch ),
          :subtitle      => 'Subtitle',
          :title         => 'Title',
          :description   => 'Description',
          :start_date    => @start_date.to_s,
          :end_date      => @end_date.to_s,
          :weight        => 1,
          :offer         => Factory(:app).primary_offer,
          :author        => Factory(:employee),
          :button_url    => 'https://www.tapjoy.com',
        }
      }
    end

    context 'when called with valid parameters' do
      before :each do
        post 'create', @options
      end

      it 'shows a notice' do
        flash[:notice].should == 'Featured content was successfully created.'
      end

      it 'redirects to tools/featured_contents/index' do
        response.should redirect_to(tools_featured_contents_path)
      end

      context 'when called without offer' do
        before :each do
          @options[:featured_content][:featured_type] = FeaturedContent::TYPES_MAP[FeaturedContent::NEWS]
          @options[:featured_content][:offer]         = nil
          post 'create', @options
        end

        it 'creates a default offer' do
          assigns[:featured_content].offer.item_type.should == 'GenericOffer'
        end

        it 'sets button_url to be NO_URL' do
          assigns[:featured_content].button_url.should == FeaturedContent::NO_URL
        end
      end
    end

    context 'when called with invalid parameters' do
      context 'when start_date > end_date' do
        before :each do
          @start_date += 5.days
          @options[:featured_content][:start_date] = @start_date.to_s
          post 'create', @options
        end

        it 'flashes an error' do
          response.session[:flash][:error].should == 'End Date must be equal to or greater than Start Date.'
        end

        it 'renders tools/featured_content/new' do
          response.should render_template('tools/featured_contents/new')
        end
      end

      context 'when when platforms is empty' do
        before :each do
          @options[:featured_content][:platforms] = []
          post 'create', @options
        end

        it 'flashes an error' do
          assigns[:featured_content].errors.on(:platforms).should == "can't be blank"
        end

        it 'renders tools/featured_content/new' do
          response.should render_template('tools/featured_contents/new')
        end
      end
    end
  end

  describe '#edit' do
    before :each do
      @featured_content = Factory(:featured_content)
      get 'edit', :id => @featured_content.id
    end

    context 'when success' do
      it 'returns the featured_content' do
        assigns[:featured_content].should == @featured_content
      end

      it 'set search_result_name' do
        assigns[:search_result_name].should == @featured_content.offer.search_result_name
      end
    end
  end

  describe '#update' do
    before :each do
      @featured_content = Factory(:featured_content)

      @options = {
        :id => @featured_content.id,
        :featured_content => {
          :featured_type => @featured_content.featured_type,
          :platforms     => %w( android ),
          :subtitle      => 'Subtitle1',
          :title         => 'Title1',
          :description   => @featured_content.description,
          :start_date    => @featured_content.start_date.to_s,
          :end_date      => @featured_content.end_date.to_s,
          :weight        => @featured_content.weight,
          :offer_id      => @featured_content.offer_id,
          :author_id     => @featured_content.author_id
        }
      }
    end

    context 'when called with valid parameters' do
      before :each do
        put 'update', @options
      end

      it 'shows a notice' do
        flash[:notice].should == 'Featured content was successfully updated.'
      end

      it 'updates the featured_content' do
         assigns[:featured_content].title.should == @options[:featured_content][:title]
      end

      it 'updates the tracking_offer associated with the featured_content' do
        assigns[:featured_content].tracking_offer.device_types.should == @options[:featured_content][:platforms].to_json
      end

      it 'redirects to tools/featured_contents/index' do
        response.should redirect_to(tools_featured_contents_path)
      end
    end

    context 'when called with invalid parameters' do
      context 'when start_date > end_date' do
        before :each do
          start_date = @featured_content.start_date + 5.days
          @options[:featured_content][:start_date] = start_date.to_s
          put 'update', @options
        end

        it 'flashes an error' do
          response.session[:flash][:error].should == 'End Date must be equal to or greater than Start Date.'
        end

        it 'renders tools/featured_content/edit' do
          response.should render_template('tools/featured_contents/edit')
        end
      end

      context 'when when platforms is empty' do
        before :each do
          @options[:featured_content][:platforms] = []
          put 'update', @options
        end

        it 'flashes an error' do
          assigns[:featured_content].errors.on(:platforms).should == "can't be blank"
        end

        it 'renders tools/featured_content/edit' do
          response.should render_template('tools/featured_contents/edit')
        end
      end
    end
  end

  describe '#destroy' do
    before :each do
      @featured_content = Factory(:featured_content)
      @tracking_offer_id = @featured_content.tracking_offer.id
    end

    context 'when success delete' do
      before :each do
        delete 'destroy', :id => @featured_content.id
      end

      it 'redirect to tools/featured_contents/index' do
        response.should redirect_to(tools_featured_contents_path)
      end
    end
  end
end
