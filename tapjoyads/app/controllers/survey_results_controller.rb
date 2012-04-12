class SurveyResultsController < ApplicationController

  layout 'mobile'

  prepend_before_filter :decrypt_data_param
  before_filter :read_click, :only => [ :create ]

  helper_method :testing?

  def new
    return unless verify_params([:udid, :click_key])
    @survey_offer = SurveyOffer.find_in_cache(params[:id])
    @survey_questions = @survey_offer.survey_questions
  end

  def create
    return unless verify_records([ @click, @currency ])
    if @click.installed_at?
      render 'survey_complete'
      return
    end

    @now = Time.zone.now
    @survey_offer = SurveyOffer.find_in_cache(params[:id])
    return unless verify_records([ @survey_offer ])
    @survey_questions = @survey_offer.survey_questions

    answers = {}
    @survey_questions.each do |question|
      if params[question.id].blank?
        @missing_params = true
        render :new
        return
      end
      answers[question.text] = params[question.id]
    end

    if testing?
      render 'survey_complete'
      return
    end

    save_survey_result(answers)

    message = {
      :click_key => @click.key,
      :install_timestamp => @now.to_f.to_s,
      :http_request_env => request.spoof_env
    }
    Sqs.send_message(QueueNames::CONVERSION_TRACKING, message.to_json)

    render 'survey_complete'
  end

  private

  def read_click
    if testing?
      @click = Click.new
      @currency = Currency.new
    else
      @click = Click.find(params[:click_key], :consistent => true)
      @currency = Currency.find_in_cache(@click.currency_id)
    end
  end

  def save_survey_result(answers)
    survey_result = SurveyResult.new
    survey_result.udid = params[:udid]
    survey_result.click_key = params[:click_key]
    survey_result.geoip_data = geoip_data
    survey_result.answers = answers
    survey_result.save

    web_request = WebRequest.new(:time => @now)
    web_request.put_values('survey_result', params, ip_address, geoip_data, request.headers['User-Agent'])
    web_request.offer_id          = @click.offer_id
    web_request.advertiser_app_id = @click.advertiser_app_id
    web_request.publisher_app_id  = @click.publisher_app_id
    web_request.udid              = @click.udid
    web_request.publisher_user_id = @click.publisher_user_id
    web_request.currency_id       = @click.currency_id
    web_request.viewed_at         = @click.viewed_at
    web_request.source            = @click.source
    web_request.publisher_amount  = @click.publisher_amount
    web_request.advertiser_amount = @click.advertiser_amount
    web_request.tapjoy_amount     = @click.tapjoy_amount
    web_request.currency_reward   = @click.currency_reward
    web_request.click_key         = @click.key
    @survey_questions.each do |question|
      web_request.survey_question_id = question.id
      web_request.survey_answer      = answers[question.text]
      web_request.save
    end
  end

  def testing?
    params[:udid] == 'just_looking'
  end
end
