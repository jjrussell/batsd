module SprocketHelper
  def js_tag(src, options={})
    if DEBUG_ASSETS
      # extract individual files from sprockets directives
      ASSETS[src].to_a.map do |js|
        content_tag :script, "", options.merge({:type => "text/javascript", :src => path_for(js, "js")})
      end.join("\n").html_safe
    else
      content_tag :script, "", options.merge({:type => "text/javascript", :src => path_for(src, "js")})
    end
  end

  def css_tag(src, options={})
    if DEBUG_ASSETS
      # extract individual files from sprockets directives
      ASSETS[src].to_a.map do |css|
        content_tag :link, "", options.merge({ :rel => "stylesheet", :href => path_for(css, "css") })
      end.join("\n").html_safe
    else
      content_tag :link, "", options.merge({ :rel => "stylesheet", :href => path_for(src, "css") })
    end
  end

  def embed_js(src, options={})
    src_code = ASSETS[src].to_s

    content_tag :script, src_code, options.merge({:type => "text/javascript"})
  end

  def path_for(src, ext)
    src = src.logical_path if src.respond_to? :logical_path
    src = src.sub /\.(js|css)$/, ""
    if CACHE_ASSETS
      "#{ASSET_HOST}/assets/#{src}-#{ASSETS[src].digest}.#{ext}"
    else
      "#{ASSET_HOST}/assets/#{src}.#{ext}"
    end
  end
end
