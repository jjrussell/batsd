module SprocketHelper
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

  def embed_js(src, options={})
    src_code = ASSETS[src].to_s

    content_tag :script, src_code, options.merge({:type => "text/javascript"})
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
