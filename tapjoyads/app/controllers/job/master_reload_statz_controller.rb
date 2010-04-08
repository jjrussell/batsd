class Job::MasterReloadStatzController < Job::JobController
  
  def index
    sess = Patron::Session.new
    sess.base_url = 'localhost:9898'
    sess.timeout = 200
    sess.username = 'internal'
    sess.password = 'TJ73business'
    sess.auth_type = :digest

    sess.get("/statz.json?reload=1")
    
    render :text => 'ok'
  end
  
end