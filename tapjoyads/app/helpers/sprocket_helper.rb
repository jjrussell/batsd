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

  private

  def path_for(logical_path, ext)
    src = CACHE_ASSETS && ASSETS.digest_list && ASSETS.digest_list[logical_path]

    if src.blank?
      digest = ASSETS[logical_path].digest

      raise "Cannot find file: " + logical_path if digest.blank?

      src = "#{logical_path}-#{digest}.#{ext}"
    end

    "#{ASSET_HOST}/assets/#{src}"
  end

end
