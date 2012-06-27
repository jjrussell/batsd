class UserEventsController < ApplicationController

  USER_EVENT_SALT = '(jdfj(DF(#{&FD@<SDXEDDD^sf3ef3s}'

  before_filter :check_params

  def create
    event = UserEvent.new(params)
    if event.valid?
      event.save
      render :text => t('user_event.success.created'), :status => :created
    else
      render :text => t('user_event.error.bad_event'), :status => :not_acceptable
    end
  end

  private

  def check_params
    verify_params([ :verifier, :app_id, :udid, :type ])
    app = App.find_in_cache(params[:app_id])
    render :text => t('user_event.error.bad_params'), :status => :precondition_failed and return unless app
    render :text => t('user_event.error.bad_verifier'), :status => :precondition_failed and return unless verified?(app)
    #Using Integer(n) raises exceptions when n isn't a valid int, instead of n.to_i(), which would return 0
    type = UserEvent::EVENT_TYPE_IDS[Integer(params[:event_type_id])] rescue nil
    render :text => t('user_event.error.bad_params'), :status => :precondition_failed and return unless type
  end

  def verified?(app)
    verifier = params.delete(:verifier)
    params_string = params.values.map { |val| "#{val}" }.join(':')
    verifier == Digest::SHA1.digest(app.secret_key + params_string)
  end


end
