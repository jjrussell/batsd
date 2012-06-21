require 'spec_helper'

describe Dashboard::ReportingController do
  context 'with a non-logged in user' do
    it 'responds with redirect' do
      get(:index)
      response.should redirect_to(login_path(:goto => reporting_index_path))
    end
  end

  context 'with a logged in user' do
    before :each do
      @user = FactoryGirl.create(:user)
      @partner = FactoryGirl.create(:partner)
      @user.partners << @partner
      activate_authlogic
      login_as(@user)
    end

    describe '#index' do
      it 'renders index if there are no offers' do
        get(:index)
        response.should be_success
        should render_template('reporting/index')
      end
    end

    context 'with offers' do
      before :each do
        @app = FactoryGirl.create(:app, :partner => @partner)
      end

      describe '#index' do
        it 'redirects to reporting path' do
          @app2 = FactoryGirl.create(:app, :partner => @partner)
          get(:index)
          response.should redirect_to(reporting_path(@app.primary_offer))
          session[:last_shown_app] = @app2.id
          get(:index)
          response.should redirect_to(reporting_path(@app2.primary_offer))
          session[:last_shown_app] = 'wah'
          get(:index)
          response.should redirect_to(reporting_path(@app.primary_offer))
        end
      end

      describe '#show' do
        it 'renders html' do
          UdidReports.should_receive(:get_available_months).with(@app.id).and_return(['stuff'])
          get(:show, :id => @app.id)
          response.should be_success
          assigns(:udids).should_not be_nil
          session[:last_shown_app].should == @app.id
        end

        it 'renders redirect for invalid offer' do
          get(:show, :id => 'something')
          response.should redirect_to(reporting_index_path)
          flash[:notice].should == "Unknown offer id"
        end

        it "does not change last_shown_app if offer isn't app" do
          video_offer = FactoryGirl.create(:video_offer)
          primary_offer = Offer.new(:item => video_offer)
          @partner.offers << primary_offer
          get(:show, :id => @app.id)
          get(:show, :id => video_offer.id)
          @app.id.should == session[:last_shown_app]
        end

        it 'renders json' do
          Appstats.any_instance.should_receive(:graph_data).with(:offer => @app.primary_offer, :admin_user => false).and_return('data!')
          get(:show, :id => @app.id, :format => 'json')
          response.should be_success
          JSON.parse(response.body)['data'].should_not be_nil
        end

        it 'renders with custom parameters' do
          Appstats.any_instance.should_receive(:graph_data).with(:offer => @app.primary_offer, :admin_user => false).and_return('data!')
          start_time = Time.zone.parse('2011-02-15').beginning_of_day
          end_time = Time.zone.parse('2011-02-18').end_of_day
          get(:show, :id => @app.id, :format => 'json', :date => '2011-02-15', :end_date => '2011-02-18', :granularity => 'daily')
          appstats = assigns(:appstats)
          appstats.start_time.should == start_time
          appstats.end_time.should == end_time
          appstats.granularity.should == :daily
        end
      end

      describe '#export' do
        before :each do
          @end_time = Time.parse('2011-02-15')
          @start_time = @end_time - 23.hours
          Timecop.freeze(@end_time) do
            Appstats.any_instance.stub(:to_csv).and_return(['a','b'])
            post(:export, :id => @app.id)
          end
        end


        it 'sends a csv response' do
          response.content_type.should =~ /csv/
          response.should be_success
          response.body.should == "a\nb"
          filename = eval(response.header['Content-Disposition'].split("filename=").last)
          filename.should == "#{@app.id}_#{@start_time.to_s(:yyyy_mm_dd)}_#{@end_time.to_s(:yyyy_mm_dd)}.csv"
        end

        it 'assigns appstats' do
          assigns(:appstats).should_not be_nil
          appstats = assigns(:appstats)
          appstats.start_time.should == @start_time
          appstats.end_time.should == @end_time + 1.hour
          appstats.granularity.should == :hourly
          appstats.app_key.should == @app.id
          appstats.instance_variable_get('@stat_prefix').should == "app"
          appstats.intervals.should_not be_nil
        end
      end

      describe '#download_udids' do
        before :each do
          @date = Time.zone.now.to_s(:yyyy_mm_dd)
          UdidReports.should_receive(:get_monthly_report).with(@app.id, @date).and_return('yay,udids')
          post(:download_udids, :id => @app.id, :date => @date)
        end


        it 'sends a csv response' do
          response.content_type.should =~ /csv/
          response.should be_success
          response.body.should == "yay,udids"
          filename = eval(response.header['Content-Disposition'].split("filename=").last)
          filename.should == "#{@app.id}_#{@date}.csv"
        end
      end

      describe '#regenerate_api_key' do
        before :each do
          @api_key = @user.api_key
        end

        it 'regenerates api key' do
          post(:regenerate_api_key)
          @user.reload
          @user.api_key.should_not == @api_key
          flash[:notice].should == "You have successfully regenerated your API key."
          response.should redirect_to(api_reporting_index_path)
        end

        it 'renders error for invalid user' do
          @user.update_attribute(:reseller_id, 1)
          post(:regenerate_api_key)
          @user.reload
          @user.api_key.should == @api_key
          flash[:error].should == "Error regenerating the API key. Please try again."
          response.should redirect_to(api_reporting_index_path)
        end
      end

      describe '#aggregate' do
        it 'renders html' do
          get(:aggregate, :format => 'html')
          should render_template('shared/aggregate')
        end

        it 'renders json' do
          Appstats.any_instance.should_receive(:graph_data).and_return('yup')
          get(:aggregate, :format => 'json')
          assigns(:appstats).should_not be_nil
          appstats = assigns(:appstats)

          start_time = Time.zone.now.beginning_of_hour - 23.hours
          end_time = start_time + 24.hours
          appstats.start_time.should == start_time
          appstats.end_time.should == end_time
          appstats.granularity.should == :hourly
          appstats.app_key.should == @partner.id
          appstats.instance_variable_get('@stat_prefix').should == "partner"
          appstats.intervals.should_not be_nil

          json = JSON.parse(response.body)
          json['data'].should == 'yup'
        end
      end

      describe '#export_aggregate' do
        before :each do
          Appstats.any_instance.stub(:to_csv).and_return(['a','b'])
          @end_time = Time.zone.parse('2011-02-15')
          @start_time = @end_time - 23.hours
          Timecop.freeze(@end_time) do
            post(:export_aggregate)
          end
        end


        it 'sends a csv response' do
          response.content_type.should =~ /csv/
          response.should be_success

          response.body.should == "a\nb"
          filename = eval(response.header['Content-Disposition'].split("filename=").last)
          filename.should == "all_#{@start_time.to_s(:yyyy_mm_dd)}_#{@end_time.to_s(:yyyy_mm_dd)}.csv"
        end

        it 'assigns appstats' do
          assigns(:appstats).should_not be_nil
          appstats = assigns(:appstats)
          appstats.start_time.should == @start_time
          appstats.end_time.should == @end_time + 1.hour
          appstats.granularity.should == :hourly
          appstats.app_key.should == @partner.id
          appstats.instance_variable_get('@stat_prefix').should == "partner"
          appstats.intervals.should_not be_nil
        end
      end
    end
  end
end
