##
# Defines the JobRunner module, which is used to run "jobs" accross a distributed system.
# A Job is simply a script, defined under the RAILS_ROOT/apps/jobs directory, which should
# be run on a periodic basis.
# Influenced heavily by the ActiveMessaging poller.
# Author: Stephen McCarthy
# 

module JobRunner
  
  class Gateway
    cattr_accessor :jobs
    @@jobs = []

    class << self
      def load_jobs
        path = File.expand_path("#{APP_ROOT}/config/jobs.rb")
        begin
          load path
        rescue MissingSourceFile
          Rails.logger.warn "JobRunner: no #{path} file to load"
        rescue
          raise $!, " JobRunner: problems trying to load '#{path}': \n\t#{$!.message}"
        end
      end
      
      def add_job job_path, interval
        jobs.push(Job.new(job_path, interval))
      end
    
      def define
        yield self
      end
      
      def start
        puts "JobRunner: starting"
        Rails.logger.info "JobRunner: starting"
        Rails.logger.flush
        jobs.each do |job|
          set_next_run_time job
        end
        
        base_url = case ENV['RAILS_ENV']
        when 'production' then 'http://localhost:9898'
        when 'test' then 'http://localhost:9898'
        else 'http://localhost:3000'
        end
        
        begin
          loop do
            now = Time.now.utc
            jobs.each do |job|
              if now > job.next_run_time
                Rails.logger.info "JobRunner: Running #{job.job_path}"
                Rails.logger.flush
                Thread.new(job) do |job|
                  begin
                    sess = Patron::Session.new
                    sess.base_url = base_url
                    sess.timeout = 60
                    sess.username = 'internal'
                    sess.password = AuthenticationHelper::USERS[sess.username]
                    sess.auth_type = :digest

                    sess.get("/job/#{job.job_path}")
                  rescue Exception => e
                    Rails.logger.warn "Error running job #{job.job_path}: #{e}"
                    Rails.logger.flush
                  end
                end
                set_next_run_time job
              end
            end
            sleep(1)
          end
        rescue Interrupt
          Rails.logger.info "JobRunner: caught interrupt"
        ensure
          stop
        end
      end
      
      ##
      # Set the next run time for a job to a random value between now and (now + 2 * job.interval).
      # This ensures that all jobs across the system don't run at the same time, while
      # also keeping the average interval equal to the specified interval.
      def set_next_run_time job
        job.next_run_time = Time.now.utc + rand(job.interval * 2)
      end
      
      def stop
        puts "JobRunner: Stopping"
        Rails.logger.info "JobRunner: Stopping"
        Rails.logger.flush
      end
    end
  end
  
  class Job
    attr_accessor :job_path, :interval, :next_run_time
    def initialize job_path, interval
      @job_path = job_path
      @interval = interval
    end
  end
end