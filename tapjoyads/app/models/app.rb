class App < SimpledbResource
  include Counter
  
  def initialize(key)
    super 'app', key
    
    next_run_time = (Time.now + 1.minutes).to_f.to_s
    put('next_run_time', next_run_time)
  end
end