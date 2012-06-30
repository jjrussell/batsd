class UserEventsController < ApplicationController

  def create
    begin
      event = UserEvent.new(params)
      event.save
      Rails.logger.info "Successfully created UserEvent with params #{params.inspect}"
      render :text => I18n.t('user_event.success.created'), :status => :ok
    rescue Exception => error
      Rails.logger.info "Error while attempting to create UserEvent with params #{params.inspect}\n#{error.message}"
      render :text => error.message, :status => :bad_request
    end
  end

end
