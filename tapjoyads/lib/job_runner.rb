##
# Defines the JobRunner module, which is used to run "jobs" accross a distributed system.
# A Job is simply a script, defined under the RAILS_ROOT/apps/jobs directory, which should
# be run on a periodic basis.
# Influenced heavily by the ActiveMessaging poller.
# Author: Stephen McCarthy
# 

module JobRunner
  
  
  class Gateway
    @@jobs = {}
    @@next_update_at = Time.now.utc
    
    class << self
      def get_active_jobs
        jobs_hash = {}
        if MACHINE_TYPE == 'masterjobs'
          active_jobs = Job.active.by_job_type('master')
        elsif MACHINE_TYPE == 'jobs' || MACHINE_TYPE == 'test'
          active_jobs = Job.active.by_job_type('queue')
        else
          active_jobs = []
          Rails.logger.info "JobRunner: Not running any jobs. Not a job server."
        end
        active_jobs.each do |job|
          jobs_hash[job.id] = job
        end
        jobs_hash
      end
      
      def load_jobs
        @@jobs = get_active_jobs
        @@jobs.values.each do |job|
          job.set_next_run_time
          Rails.logger.info "Next run time for #{job.job_path}: #{job.next_run_time}"
        end
        @@next_update_at = Time.now.utc + 1.minute
      end
      
      def update_jobs
        active_jobs = nil
        begin
          active_jobs = get_active_jobs
        rescue Exception => e
          Rails.logger.error "JobRunner: Failed to update jobs. #{e}"
          @@next_update_at = Time.now.utc + 1.minute
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
        @@next_update_at = Time.now.utc + 1.minute
        Rails.logger.info "JobRunner: Updated job config. Next update at #{@@next_update_at}"
      end
      
      def start
        Rails.logger.info "JobRunner: running"
        load_jobs
        Rails.logger.flush
        
        base_url = case ENV['RAILS_ENV']
        when 'production' then 'http://localhost:9898'
        when 'test' then 'http://localhost:9898'
        else 'http://localhost:3000'
        end
        
        sleep(rand * 5)
        begin
          loop do
            now = Time.now.utc
            update_jobs if now > @@next_update_at
            Rails.logger.flush
            @@jobs.values.each do |job|
              if now > job.next_run_time
                Rails.logger.info "#{now.to_s(:db)} - JobRunner: Running #{job.job_path}"
                Rails.logger.flush
                Thread.new(job.job_path) do |job_path|
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
      
      def stop
        Rails.logger.info "JobRunner: Stopping"
        Rails.logger.flush
      end
    end
  end
  
end
