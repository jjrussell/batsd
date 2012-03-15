require 'rake'
require 'rake/tasklib'

require 'sprockets'
require 'logger'

module Rake
  # Simple Sprockets compilation Rake task macro.
  #
  #   Rake::SprocketsTask.new do |t|
  #     t.environment = Sprockets::Environment.new
  #     t.output      = "./public/assets"
  #     t.assets      = %w( application.js application.css )
  #   end
  #
  class SprocketsTask < Rake::TaskLib
    # Name of the task. Defaults to "assets".
    #
    # The name will also be used to suffix the clean and clobber
    # tasks, "clean_assets" and "clobber_assets".
    attr_accessor :name

    # `Environment` instance used for finding assets.
    #
    # You'll most likely want to reassign `environment` to your own.
    #
    #   Rake::SprocketsTask.new do |t|
    #     t.environment = Foo::Assets
    #   end
    #
    def environment
      if !@environment.is_a?(Sprockets::Base) && @environment.respond_to?(:call)
        @environment = @environment.call
      else
        @environment
      end
    end
    attr_writer :environment

    # Directory to write compiled assets too. As well as the manifest file.
    #
    #   t.output = "./public/assets"
    #
    attr_accessor :output

    # Array of asset logical paths to compile.
    #
    #   t.assets = %w( application.js jquery.js application.css )
    #
    attr_accessor :assets

    # Number of old assets to keep.
    attr_accessor :keep

    # Logger to use during rake tasks. Defaults to using stderr.
    #
    #   t.logger = Logger.new($stdout)
    #
    attr_accessor :logger

    # Returns logger level Integer.
    def log_level
      @logger.level
    end

    # Set logger level with constant or symbol.
    #
    #   t.log_level = Logger::INFO
    #   t.log_level = :debug
    #
    def log_level=(level)
      if level.is_a?(Integer)
        @logger.level = level
      else
        @logger.level = Logger.const_get(level.to_s.upcase)
      end
    end

    def initialize(name = :assets)
      @name         = name
      @environment  = lambda { Sprockets::Environment.new(Dir.pwd) }
      @logger       = Logger.new($stderr)
      @logger.level = Logger::INFO
      @keep         = 2

      yield self if block_given?

      define
    end

    # Define tasks
    def define
      desc name == :assets ? "Compile assets" : "Compile #{name} assets"
      task name do
        with_logger do
          manifest.compile(assets)
        end
      end

      desc name == :assets ? "Remove all assets" : "Remove all #{name} assets"
      task "clobber_#{name}" do
        with_logger do
          manifest.clobber
        end
      end

      task :clobber => ["clobber_#{name}"]

      desc name == :assets ? "Clean old assets" : "Clean old #{name} assets"
      task "clean_#{name}" do
        with_logger do
          manifest.clean(keep)
        end
      end

      task :clean => ["clean_#{name}"]
    end

    private
      # Returns cached indexed environment
      def index
        @index ||= environment.index
      end

      # Returns manifest for tasks
      def manifest
        @manifest ||= Sprockets::Manifest.new(index, output)
      end

      # Sub out environment logger with our rake task logger that
      # writes to stderr.
      def with_logger
        old_logger = index.logger
        index.logger = @logger
        yield
      ensure
        index.logger = old_logger
      end
  end
end
