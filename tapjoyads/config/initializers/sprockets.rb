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

ass = Sprockets::Environment.new

ass.append_path 'app/assets/javascripts'
ass.append_path 'app/assets/stylesheets'
ASSETS_PATH = "#{Rails.root}/public/assets/"

if CACHE_ASSETS
  ass.js_compressor = Uglifier.new
  ass.css_compressor = CompressCss.new

  # build immutable index on startup
  ass = ass.index
  ass.each_logical_path do |l|
    STDOUT.flush
    ass[l]
  end
end
ASSETS = ass
