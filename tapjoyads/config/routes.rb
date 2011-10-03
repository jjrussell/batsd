ActionController::Routing::Routes.draw do |map|
  map.connect 'healthz', :controller => :healthz, :action => :index

  if MACHINE_TYPE == 'dashboard'
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/dashboard.rb'))
  elsif MACHINE_TYPE == 'games'
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/games.rb'))
  elsif MACHINE_TYPE == 'website'
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/website.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/dashboard.rb'))
  elsif MACHINE_TYPE == 'web'
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/web.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/legacy.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/default.rb'))
  elsif MACHINE_TYPE == 'jobs' || MACHINE_TYPE == 'masterjobs'
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/default.rb'))
  else
    # jobs/masterjobs/test/dev
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/dashboard.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/games.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/website.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/web.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/legacy.rb'))
    ActionController::Routing::Routes.add_configuration_file(Rails.root.join('config/routes/default.rb'))
  end
end
