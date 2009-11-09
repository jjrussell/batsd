class AppStatsJob
  def run
    current_time = Time.now.to_f.to_s
    response = SimpledbResource.query('app', 'time, app_id', "time < #{current_time}", 'time asc')
    Rails.logger.log(response.items[0].attributes[0].value + ' ' + response.items[0].attributes[1].value)
  end
end