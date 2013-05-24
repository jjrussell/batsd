class Job::MasterUpdateAppActiveGamerCountController < Job::JobController
  def index
    most_recent = VerticaCluster.query('analytics.connects', :select => 'max(time)').first[:max]

    end_time   = most_recent.beginning_of_day
    start_time = end_time - 7.days

    time_conditions = "time >= '#{start_time.to_s(:db)}' AND time < '#{end_time.to_s(:db)}'"

    VerticaCluster.query('analytics.connects', {
        :select     => 'app_id, count(distinct gamer_id) as active_gamer_count',
        :join       => 'analytics.gamer_devices on connects.udid = gamer_devices.device_id',
        :conditions => "#{time_conditions}",
        :group      => 'app_id' }).each do |result|
      app = App.find_by_id(result[:app_id])
      if app
        app.active_gamer_count = result[:active_gamer_count]
        app.save if app.changed?
      end
    end

    render :text => 'ok'
  end
end
