# Let us emulate production webserver boxes!
if Rails.env.development? && MACHINE_TYPE == 'webserver'
  ActiveRecord::Base.establish_connection :development_sqlite
end
