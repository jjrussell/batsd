# Let us emulate production webserver boxes!
if Rails.env.development? && (MACHINE_TYPE == 'webserver' || MACHINE_TYPE == 'connect' || MACHINE_TYPE == 'offers')
  ActiveRecord::Base.establish_connection :development_sqlite
end
