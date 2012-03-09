class CompressCss
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

ASSETS = Sprockets::Environment.new

ASSETS.append_path 'app/assets/javascripts'
ASSETS.append_path 'app/assets/stylesheets'
ASSETS_PATH = "#{Rails.root}/public/assets/"

if CACHE_ASSETS
  ASSETS.js_compressor = Uglifier.new
  ASSETS.css_compressor = CompressCss.new

  # minify all on startup
  print "Loading static assets "
  ASSETS.each_logical_path do |l|
    print "."
    STDOUT.flush
    ASSETS[l]
  end
  puts
end
