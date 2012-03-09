require 'static_compiler'

module Sprockets
  class Environment
    attr_accessor :digest_list
    @digest_list = {}
  end

  # Monkey patch sprockets to properly minify in Production mode.
  class SassTemplate
    def evaluate(context, locals, &block)
      # Use custom importer that knows about Sprockets Caching
      cache_store = SassCacheStore.new(context.environment)

      options = {
        :style => CACHE_ASSETS ? :compressed : :nested,
        :filename => eval_file,
        :line => line,
        :syntax => syntax,
        :cache_store => cache_store,
        :importer => SassImporter.new(context, context.pathname),
        :load_paths => context.environment.paths.map { |path| SassImporter.new(context, path) }
      }

      ::Sass::Engine.new(data, options).render
    rescue ::Sass::SyntaxError => e
      # Annotates exception message with parse line number
      context.__LINE__ = e.sass_backtrace.first[:line]
      raise e
    end
  end
end


ASSETS = Sprockets::Environment.new

ASSETS.append_path 'app/assets/javascripts'
ASSETS.append_path 'app/assets/stylesheets'
ASSETS_PATH = "#{Rails.root}/public/assets/"

if CACHE_ASSETS
  ASSETS.js_compressor = Uglifier.new
  compiler = Sprockets::Joy::StaticCompiler.new(ASSETS, ASSETS_PATH, {:digest => true})
  compiler.compile

  if File.exists?("#{ASSETS_PATH}asset_manifest.yml")
    ASSETS.digest_list = YAML::load_file("#{ASSETS_PATH}asset_manifest.yml")
  end
end
