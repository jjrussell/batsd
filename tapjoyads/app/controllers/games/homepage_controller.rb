class Games::HomepageController < GamesController
  
  before_filter :require_complete_gamer, :only => 'real_index'
  
  # TODO: switch this to index when we're ready to launch
  def real_index
    @device = Device.new(:key => current_gamer.udid)
    device_apps = @device.apps
    @external_publishers = []
    ExternalPublisher.load_all.each do |app_id, external_publisher|
      next if device_apps[app_id].blank?
      
      external_publisher.last_run_time = device_apps[app_id].to_i
      @external_publishers << external_publisher
    end
    
    @external_publishers.sort! do |e1, e2|
      e2.last_run_time <=> e1.last_run_time
    end
  end
  
private
  
  def require_complete_gamer
    if current_gamer.blank?
      redirect_to games_login_path 
    elsif current_gamer.udid.blank?
      redirect_to link_device_games_registrations_path
    end
  end
  
end
