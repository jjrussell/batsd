ActionController::Routing::Routes.draw do |map|
  map.connect 'healthz', :controller => :healthz, :action => :index

  routes = case MACHINE_TYPE
  when 'dashboard'
    %w( dashboard api sdks )
  when 'website'
    %w( games website api sdks )
  when 'web'
    %w( web legacy default )
  when 'jobs', 'masterjobs'
    %w( default )
  else
    # test/dev
    %w( api sdks dashboard games website web legacy default )
  end

  routes.each do |route|
    path = Rails.root.join("config/routes/#{route}.rb")
    ActionController::Routing::Routes.add_configuration_file(path)
  end
end
