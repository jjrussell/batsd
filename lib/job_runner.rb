class JobRunner
  UPDATE_INTERVAL = 1.minute

  @@jobs = {}
  @@next_update_at = Time.now.utc
  @@unicorn_pid = ''

  def self.get_active_jobs
    jobs_hash = {}
    return jobs_hash unless Rails.env.production?

    case MACHINE_TYPE
    when 'testserver', 'staging'
      active_jobs = Job.active.by_job_type('queue')
    when 'jobserver'
      # TODO (amdtech): Once we have the second cluster for no database access, update this to only get database jobs
      active_jobs = Job.active.uses_database(true).by_job_type('queue')
    when 'queues-nodb'
      active_jobs = Job.active.uses_database(false).by_job_type('queue')
    else
      active_jobs = []
      Rails.logger.info "JobRunner: Not running any jobs. Not a job server."
    end

    active_jobs.each do |job|
      jobs_hash[job.id] = job
    end
    jobs_hash
  end

  def self.get_unicorn_pid
    base_dir = File.expand_path("server", Rails.root)
    `#{base_dir}/unicorn_master_pid.rb`.gsub(' ', '_')
  end

  def self.load_jobs
    @@jobs = get_active_jobs
    @@jobs.values.each do |job|
      job.set_next_run_time
      Rails.logger.info "Next run time for #{job.job_path}: #{job.next_run_time}"
    end
    @@next_update_at = Time.now.utc + UPDATE_INTERVAL
    @@unicorn_pid = get_unicorn_pid
  end

  def self.update_jobs
    active_jobs = nil
    begin
      active_jobs = get_active_jobs
    rescue Exception => e
      Rails.logger.error "JobRunner: Failed to update jobs. #{e}"
      @@next_update_at = Time.now.utc + UPDATE_INTERVAL
      return
    end
    (@@jobs.keys - active_jobs.keys).each do |deleted_job_id|
      @@jobs.delete(deleted_job_id)
    end
    (active_jobs.keys - @@jobs.keys).each do |new_job_id|
      @@jobs[new_job_id] = active_jobs[new_job_id]
      @@jobs[new_job_id].set_next_run_time
    end
    @@jobs.each do |job_id, job|
      next unless active_jobs[job_id].updated_at > job.updated_at
      @@jobs[job_id] = active_jobs[job_id]
      @@jobs[job_id].set_next_run_time
    end
    @@next_update_at = Time.now.utc + UPDATE_INTERVAL
    @@unicorn_pid = get_unicorn_pid
    Rails.logger.info "JobRunner: Updated job config. Next update at #{@@next_update_at}"
  end

  def self.start
    Rails.logger.info "JobRunner: running"
    ActiveRecord::Base.establish_connection('job_runner')
    load_jobs
    Rails.logger.flush

    base_url = Rails.env.production? ? 'http://localhost:9898' : ''

    Dir.mkdir(Job::CONCURRENCY_DIR) unless File.exists?(Job::CONCURRENCY_DIR)

    sleep(rand * 5)
    begin
      loop do
        now = Time.now.utc
        update_jobs if now > @@next_update_at
        Rails.logger.flush
        @@jobs.values.each do |job|
          if now > job.next_run_time && (job.max_concurrency == 0 || Dir.glob("#{Job::CONCURRENCY_DIR}/#{job.concurrency_filename(@@unicorn_pid)}*").size < job.max_concurrency)
            Rails.logger.info "#{now.to_s(:db)} - JobRunner: Running #{job.job_path}"
            Rails.logger.flush
            path = job.job_path
            if job.max_concurrency > 0
              concurrency_filename = job.concurrency_filename(@@unicorn_pid, UUIDTools::UUID.random_create.hexdigest)
              path << (path =~ /\?/ ? '&' : '?')
              path << "concurrency_filename=#{concurrency_filename}"
              File.open("#{Job::CONCURRENCY_DIR}/#{concurrency_filename}", 'w') {}
            end
            Thread.new(path) do |job_path|
              sess = Patron::Session.new
              sess.base_url = base_url
              sess.timeout = 1
              sess.username = 'internal'
              sess.password = AuthenticationHelper::USERS[sess.username]
              sess.auth_type = :digest
              sess.get("/job/#{job_path}")
            end
            job.set_next_run_time
          end
        end
        sleep(rand() / 10)
      end
    rescue Interrupt
      Rails.logger.info "JobRunner: caught interrupt"
    ensure
      stop
    end
  end

  def self.stop
    Rails.logger.info "JobRunner: Stopping"
    Rails.logger.flush
  end

end
