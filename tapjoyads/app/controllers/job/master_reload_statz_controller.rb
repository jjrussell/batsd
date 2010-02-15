class Job::MasterReloadStatzController < Job::JobController
  
  def index
    sess = Patron::Session.new
    sess.base_url = 'localhost:9898'
    sess.timeout = 60
    sess.username = 'internal'
    sess.password = AuthenticationHelper::USERS[sess.username]
    sess.auth_type = :digest

    sess.get("/statz.json?reload=1")
  end
  
end