ActionController::Routing::Routes.draw do |map|
  map.connect 'healthz', :controller => :healthz, :action => :index

  routes = case MACHINE_TYPE
  when 'dashboard'
    ['dashboard']
  when 'games'
    ['games']
  when 'website'
    ['website','dashboard']
  when 'web'
    ['web','legacy','default']
  when 'jobs', 'masterjobs'
    ['default']
  else
    # test/dev
    ['dashboard','games','website','web','legacy','default']
  end

  routes.each do |route|
    path = Rails.root.join("config/routes/#{route}.rb")
    ActionController::Routing::Routes.add_configuration_file(path)
  end
end
