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
      attr_accessor :is_cached, :debug, :host

      def assets
        @asset_env || init_assets
      end

      def init_assets
        @asset_env = Sprockets::Environment.new

        @asset_env.append_path 'app/assets/javascripts'
        @asset_env.append_path 'app/assets/stylesheets'

        if !is_cached
          @asset_env.cache = ActiveSupport::Cache::FileStore.new(File.join(Rails.root, "tmp", "cache", "assets")).silence!
        end

        if is_cached
          @asset_env.js_compressor = Uglifier.new
          @asset_env.css_compressor = Sprockets::TjCompressCss.new

          # build immutable index on startup
          @asset_env = @asset_env.index
          precompiled_assets.each { |l| @asset_env[l] }
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
