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
    full_logical_path = "#{logical_path}.#{ext}" unless logical_path.split('.').last == ext

    return "#{ASSET_HOST}/assets/#{full_logical_path}" unless CACHE_ASSETS

    src = CACHE_ASSETS && ASSETS.digest_list && ASSETS.digest_list[full_logical_path]

    if src.blank?
      digest = ASSETS[full_logical_path].digest

      raise "Cannot find file: " + full_logical_path if digest.blank?

      src = "#{logical_path}-#{digest}.#{ext}"
    end

    "#{ASSET_HOST}/assets/#{src}"
  end
end
