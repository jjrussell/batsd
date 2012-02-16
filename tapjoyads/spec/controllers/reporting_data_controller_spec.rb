require 'spec_helper'
require 'rexml/document'

include REXML   # So we can avoid REXML prefix

describe ReportingDataController do
  before :each do
    fake_the_web
  end

  describe '#index' do
    before :each do
      @partner = Factory(:partner)
      @user = Factory(:user)
      @user.partners << @partner
      @partner.offers << Factory(:app).primary_offer
    end

    context 'with missing params' do
      before :each do
        @response = get(:index)
      end

      it 'responds with 400 error' do
        should respond_with(400)
      end
    end

    context 'with bad credentials' do
      before :each do
        @response = get(:index, :date => "2011-02-15", :username => @user.username, :api_key => 'poo')
      end

      it 'responds with 403 error' do
        should respond_with(403)
      end
    end

    context 'with invalid date parameter' do
      before :each do
        @response = get(:index, :date => 'poo', :username => @user.username, :api_key => @user.api_key)
      end

      it 'responds with 400 error' do
        should respond_with(400)
      end

      it 'responds with error message' do
        @response.body.should == "Invalid date"
      end
    end

    context 'with valid params, xml' do
      before :each do
        @response = get(:index, :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key, :partner_id => @partner.id)
      end
      it 'has a successful xml response' do
        should respond_with(200)
        should respond_with_content_type(:xml)
      end
    end

    context 'with valid params, json' do
      before :each do
        @response = get(:index, :format => 'json', :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key)
      end

      it 'has a successful json response' do
        should respond_with(200)
        should respond_with_content_type(:json)
      end
    end

    context 'with timezone param' do
      before :each do
        @app = @partner.offers.first
        @stats = Stats.new(:key => "app.2011-01-01.#{@app.id}", :load_from_memcache => false)
        @stats.update_stat_for_hour('logins', 12, 1)
        @stats.save!
      end

      it 'defaults to UTC when param is invalid' do
        response = get(:index, :format => 'xml', :date => "2011-01-01", :username => @user.username, :api_key => @user.api_key, :timezone => 'invalid')
        xml = Document.new response.body
        xml.elements.each("MarketingData/Timezone") do |node|
          node.text.should == '(GMT+00:00) Casablanca'
        end
        xml.elements.each("MarketingData/App/SessionsHourly") do |node|
          node.text.should == '0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0'
        end
      end

      it 'shifts values left by 8 with timezone=-8' do
        response = get(:index, :format => 'xml', :date => "2011-01-01", :username => @user.username, :api_key => @user.api_key, :timezone => '-8')
        xml = Document.new response.body
        xml.elements.each("MarketingData/Timezone") do |node|
          node.text.should == '(GMT-08:00) Pacific Time (US & Canada)'
        end
        xml.elements.each("MarketingData/App/SessionsHourly") do |node|
          node.text.should == '0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0'
        end
      end

      it 'defaults to user timezone when no timezone specified' do
        response = get(:index, :format => 'xml', :date => "2011-01-01", :username => @user.username, :api_key => @user.api_key)
        xml = Document.new response.body
        xml.elements.each("MarketingData/Timezone") do |node|
          node.text.should == '(GMT+00:00) UTC'
        end
        xml.elements.each("MarketingData/App/SessionsHourly") do |node|
          node.text.should == '0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0'
        end
      end

      after :each do
        @stats.delete_all
      end
    end
  end

  describe '#udids with data' do
    before :each do
      @partner = Factory(:partner)
      @user = Factory(:user)
      @partner.users << @user
      @offer = Factory(:app).primary_offer
      @partner.offers << @offer
      UdidReports.stubs(:get_daily_report).returns('a,b,c')
      UdidReports.stubs(:get_monthly_report).returns('a,b,c')
    end

    context 'with missing params' do
      before :each do
        @response = get(:udids)
      end

      it 'responds with 400 error' do
        should respond_with(400)
      end
    end

    context 'with invalid date parameter' do
      before :each do
        @response = get(:udids, :offer_id => @offer.id, :date => "201-02-15", :username => @user.username, :api_key => @user.api_key)
      end

      it 'responds with 404 error' do
        should respond_with(404)
      end

      it 'returns an error message' do
        @response.body.should == "Invalid date"
      end
    end

    context 'with invalid offer' do
      before :each do
        @response = get(:udids, :offer_id => 'poo', :date => "201-02-15", :username => @user.username, :api_key => @user.api_key)
      end

      it 'responds with 404 error' do
        should respond_with(404)
      end

      it 'returns an error message' do
        @response.body.should == "Unknown offer id"
      end
    end

    context 'daily with valid params' do
      before :each do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key)
      end

      it 'responds with 200 success' do
        should respond_with(200)
      end

      it 'returns a csv object' do
        should respond_with_content_type(:csv)
        filename = eval(@response.header['Content-Disposition'].split("filename=").last)
        filename.should == "#{@offer.id}_2011-02-15.csv"
        @response.body.should == 'a,b,c'
      end
    end

    context 'monthly with valid params' do
      before :each do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02", :username => @user.username, :api_key => @user.api_key)
      end

      it 'responds with 200 success' do
        should respond_with(200)
      end

      it 'returns a csv object' do
        should respond_with_content_type(:csv)
        filename = eval(@response.header['Content-Disposition'].split("filename=").last)
        filename.should == "#{@offer.id}_2011-02.csv"
        @response.body.should == 'a,b,c'
      end
    end
  end

  describe '#udids without data' do
    before :each do
      @partner = Factory(:partner)
      @user = Factory(:user)
      @partner.users << @user
      @offer = Factory(:app).primary_offer
      @partner.offers << @offer
    end

    context 'with missing params' do
      before :each do
        @response = get(:udids)
      end

      it 'responds with 400 error' do
        should respond_with(400)
      end
    end

    context 'daily with valid params' do
      before :each do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02-15", :username => @user.username, :api_key => @user.api_key)
      end

      it 'responds with 404 error' do
        should respond_with(404)
      end

      it 'responds with html content type' do
        should respond_with_content_type(:html)
      end

      it 'has error message' do
        @response.body.should == "No UDID report exists for this date"
      end
    end

    context 'monthly with valid params' do
      before :each do
        @response = get(:udids, :offer_id => @offer.id, :date => "2011-02", :username => @user.username, :api_key => @user.api_key)
      end

      it 'responds with 404 error' do
        should respond_with(404)
      end

      it 'responds with html content type' do
        should respond_with_content_type(:html)
      end

      it 'has error message' do
        @response.body.should == "No UDID report exists for this date"
      end
    end
  end
end
