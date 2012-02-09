class SurveyResultsController < ApplicationController

  layout 'mobile'

  before_filter :read_click, :only => [ :create ]

  def new
    return unless verify_params([:udid, :click_key])
    survey_offer = SurveyOffer.find_in_cache(params[:id])
    @page_title = survey_offer.name
    @survey_questions = survey_offer.survey_questions
  end

  def create
    return unless verify_records([ @currency ])
    if @click.installed_at?
      render 'survey_complete'
      return
    end

    survey_offer = SurveyOffer.find_in_cache(params[:id])
    @survey_questions = survey_offer.survey_questions

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

    device = Device.new(:key => params[:udid])
    device.survey_answers = device.survey_answers.merge(answers)
    device.save

    url = "#{API_URL}/offer_completed?click_key=#{params[:click_key]}"
    Downloader.get_with_retry(url)

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
    survey_result.geoip_data = get_geoip_data
    survey_result.answers = answers
    survey_result.save
  end

  def testing?
    params[:udid] == 'just_looking'
  end
end
