module SprocketHelper
  extend ActiveSupport::Memoizable
  def js_tag(src, options={})
    src = src.sub /\.js$/, ""
    src = path_for("#{src}", "js")

    content_tag :script, "", options.merge({:type => "text/javascript", :src => src})
  end

  def css_tag(src, options={})
    src = src.sub /\.css$/, ""
    src = path_for("#{src}", "css")

    content_tag :link, "", options.merge({:rel => "stylesheet", :href => src})
  end

  private

  def path_for(logical_path, ext)
    if CACHE_ASSETS
      full_logical_path = "#{ASSET_HOST}/assets/#{logical_path}-#{ASSETS[logical_path].digest}.#{ext}"
    else
      full_logical_path = "#{ASSET_HOST}/assets/#{logical_path}.#{ext}"
    end
  end
end
