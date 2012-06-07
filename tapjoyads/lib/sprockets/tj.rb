require 'fileutils'

module Sprockets
  class TjCompressCss
    def compress(css)
      if css.count("\n") > 2
        Sass::Engine.new(css,
           :syntax => :scss,
           :cache => false,
           :read_cache => false,
           :style => :compressed).render
        else
          css
      end
    end
  end

  module Tj
    class << self
      attr_accessor :combine, :compile, :precompile, :host
      def combine?
        @combine ||= SPROCKETS_CONFIG[:combine]
      end

      def compile?
        @compile ||= SPROCKETS_CONFIG[:compile]
      end

      def precompile?
        Rails.configuration.action_controller.perform_caching
      end

      def host
        @host ||= SPROCKETS_CONFIG[:host]
      end

      def assets
        @asset_env || init_assets
      end

      def init_assets
        @asset_env = Sprockets::Environment.new

        @asset_env.append_path 'app/assets/javascripts'
        @asset_env.append_path 'app/assets/stylesheets'

        if compile?
          @asset_env.js_compressor = Uglifier.new
          @asset_env.css_compressor = Sprockets::TjCompressCss.new
        end

        if precompile?
          # build immutable index on startup
          @asset_env = @asset_env.index

          target = File.join(::Rails.public_path, 'assets')
          compiler = StaticCompiler.new @asset_env,
                                        target,
                                        @asset_env.paths
          compiler.compile
          Rails.configuration.tj_digests = YAML::load_file("#{target}/manifest.yml")
        else
          @asset_env.cache = ActiveSupport::Cache::FileStore.new(File.join(Rails.root, "tmp", "cache", "assets")).silence!
          Rails.configuration.tj_digests = {}
        end
        @asset_env
      end

      def asset_precompiled?(src)
        precompiled_assets.include?(src)
      end

      def precompiled_assets
        @pc_assets ||= YAML::load_file(File.join(Rails.root, 'config', 'precompiled_assets.yml'))
      end
    end

    # asset manifest, per Rails 3.1 core
    # https://github.com/rails/sprockets-rails/blob/master/lib/sprockets/rails/static_compiler.rb
    class StaticCompiler
      attr_accessor :env, :target, :paths

      def initialize(env, target, paths, options = {})
        @env = env
        @target = target
        @paths = paths
        @digest = options.fetch(:digest, true)
        @manifest = options.fetch(:manifest, true)
        @manifest_path = options.delete(:manifest_path) || target
        @zip_files = options.delete(:zip_files) || /\.(?:css|html|js|svg|txt|xml)$/
      end

      def compile
        manifest = {}
        env.each_logical_path do |logical_path|
          if asset = env.find_asset(logical_path)
            manifest[logical_path] = write_asset(asset)
          end
        end
        write_manifest(manifest) if @manifest
      end

      def write_manifest(manifest)
        FileUtils.mkdir_p(@manifest_path)
        File.open("#{@manifest_path}/manifest.yml", 'wb') do |f|
          YAML.dump(manifest, f)
        end
      end

      def write_asset(asset)
        path_for(asset).tap do |path|
          filename = File.join(target, path)
          FileUtils.mkdir_p File.dirname(filename)
          asset.write_to(filename)
          asset.write_to("#{filename}.gz") if filename.to_s =~ @zip_files
        end
      end

      def path_for(asset)
        @digest ? asset.digest_path : asset.logical_path
      end
    end
  end
end
