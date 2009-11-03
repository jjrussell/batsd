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
    @@jobs = {}

    @@num_machines = MACHINES.length if defined? MACHINES
    @@num_machines ||= 1

    class << self
      def load_jobs
        Dir[APP_ROOT + '/app/jobs/*.rb'].each do |f|
          load f
        end

        path = File.expand_path("#{APP_ROOT}/config/jobs.rb")
        begin
          load path
        rescue MissingSourceFile
          Rails.logger.warn "JobRunner: no #{path} file to load"
        rescue
          raise $!, " JobRunner: problems trying to load '#{path}': \n\t#{$!.message}"
        end
      end
      
      def add_job job_name, job_class, interval
        jobs[job_name] = Job.new job_class, interval * @@num_machines
      end
    
      def define
        yield self
      end
      
      def start
        Rails.logger.info "JobRunner: starting"
        jobs.each_value do |job|
          set_next_run_time job
        end
        
        begin
          loop do
            now = Time.now
            jobs.each do |job_name, job|
              if now > job.next_run_time
                Rails.logger.info "JobRunner: Running #{job_name}"
                job.job_class.new.run
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
        job.next_run_time = Time.now + rand(job.interval * 2)
      end
      
      def stop
        Rails.logger.info "JobRunner: Stopping"
      end
    end
  end
  
  class Job
    attr_accessor :job_class, :interval, :next_run_time
    def initialize job_class, interval
      @job_class = job_class
      @interval = interval
    end
  end
end