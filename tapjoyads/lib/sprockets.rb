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

  module TJ
    attr_accessor :is_cached, :debug_mode, :root_path, :host

    def self.assets
      @assets || init_assets
    end

    def self.init_assets
      @assets = Sprockets::Environment.new

      @assets.append_path 'app/assets/javascripts'
      @assets.append_path 'app/assets/stylesheets'

      if debug_mode
        @assets.cache = ActiveSupport::Cache::FileStore.new(File.join(Rails.root, "tmp", "cache", "assets"))
      end

      if is_cached
        @assets.js_compressor = Uglifier.new
        @assets.css_compressor = Sprockets::TjCompressCss.new

        # build immutable index on startup
        @assets = @assets.index
        @assets.each_logical_path do |l|
          @assets[l].digest
        end
      end
    end
  end
end
