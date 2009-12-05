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
      def load_config
        path = File.expand_path("#{APP_ROOT}/config/jobs.rb")
        begin
          load path
        rescue MissingSourceFile
          Rails.logger.warn "JobRunner: no #{path} file to load"
        rescue
          raise $!, " JobRunner: problems trying to load '#{path}': \n\t#{$!.message}"
        end
      end
      
      ##
      # Called by the config file to add a job.
      # job_path: The path of the job, under /job.
      # options: Specify how often to run the job. Only one option should be specified.
      # Supported options are:
      #   interval: Run every X seconds, on average. 
      #   daily: Run once a day, every day X seconds after the start of the day.
      def add_job job_path, options
        jobs.push(Job.new(job_path, options))
      end
    
      def define
        yield self
      end
      
      def start
        Rails.logger.info "JobRunner: running"
        load_config
        jobs.each do |job|
          job.set_next_run_time
          Rails.logger.info "Next run time for #{job.job_path}: #{job.next_run_time}"
        end
        Rails.logger.flush
        
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
                  sess = Patron::Session.new
                  sess.base_url = base_url
                  sess.timeout = 60
                  sess.username = 'internal'
                  sess.password = AuthenticationHelper::USERS[sess.username]
                  sess.auth_type = :digest

                  sess.get("/job/#{job.job_path}")
                end
                job.set_next_run_time
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
      
      def stop
        Rails.logger.info "JobRunner: Stopping"
        Rails.logger.flush
      end
    end
  end
  
  class Job
    attr_accessor :job_path, :next_run_time
    def initialize job_path, options
      @job_path = job_path
      @options = options
      
      if options.keys.length != 1
        raise "Options must contain only one key"
      end
      
      allowable_keys = [:interval, :daily]
      unless allowable_keys.include?(options.keys.first)
        raise "Options must contain one of: #{allowable_keys.join(', ')}"
      end
      
    end
    
    ##
    # Set the next run time for a job to a random value between now and (now + 2 * job.interval).
    # This ensures that all jobs across the system don't run at the same time, while
    # also keeping the average interval equal to the specified interval.
    def set_next_run_time
      if @options[:interval]
        @next_run_time = Time.now.utc + rand(@options[:interval] * 2)
      elsif @options[:daily]
        if @next_run_time
          @next_run_time += 1.days
        else
          @next_run_time = Time.parse('00:00 GMT', Time.now.utc).utc + @options[:daily]
          if Time.now.utc > @next_run_time
            @next_run_time += 1.days
          end
        end
      end
    end
  end
end