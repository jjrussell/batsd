class UserEventsController < ApplicationController

  def create
    begin
      event = UserEvent.new(params)
      event.save
      render :text => t('user_event.success.created'), :status => :created
    rescue Exception => error
      render :text => error.message, :status => :not_acceptable
    end
  end

end
