Rails.environment = Sprockets::Environment.new

environment.append_path 'app/assets/javascripts'
environment.append_path 'app/assets/stylesheets'
