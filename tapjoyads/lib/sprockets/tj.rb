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
          precompiled_assets.each { |l| @asset_env[l] }
        else
          @asset_env.cache = ActiveSupport::Cache::FileStore.new(File.join(Rails.root, "tmp", "cache", "assets")).silence!
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
  end
end
