class Job::MasterHealthzController < Job::JobController

  def index
    File.open(MASTER_HEALTHZ_FILE, 'w') do |f|
      f.write(Time.zone.now.to_i)
    end

    render :text => 'ok'
  end

end
