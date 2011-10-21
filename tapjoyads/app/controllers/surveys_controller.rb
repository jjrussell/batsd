class SurveysController < ApplicationController
  
  layout 'iphone'
  
  before_filter :read_click, :only => [ :create ]
  
  def new
    return unless verify_params([:udid, :click_key])
  end
  
  def create
    unless verify_params([:gender, :birth_year, :postal_code], :render_missing_text => false)
      @missing_params = true
      render :action => :new
      return
    end
    
    if @click.installed_at.nil?
      answers = {
        :gender => params[:gender][0, 10],
        :birth_year => params[:birth_year][0, 10],
        :postal_code => params[:postal_code][0, 10]
      }
    
      survey_result = SurveyResult.new
      survey_result.udid = params[:udid]
      survey_result.click_key = params[:click_key]
      survey_result.geoip_data = get_geoip_data
      survey_result.answers = answers
      survey_result.save
    
      device = Device.new(:key => params[:udid])
      device.survey_answers = answers
      device.save
    
      if Rails.env == 'production'
        Downloader.get_with_retry "#{API_URL}/offer_completed?click_key=#{params[:click_key]}"
      end
    end
    
    render :template => "surveys/survey_complete"
  end
  
private
  def read_click
    @click = Click.find(params[:click_key], :consistent => true)
    @currency = Currency.find_in_cache(@click.currency_id)
    return unless verify_records([ @currency ])
  end
  
end
