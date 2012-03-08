module SprocketHelper
  def js_tag(src, options={})
    digest = digest_for("#{src}.js")

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.js"

    content_tag :script, "", options.merge({:type => "text/javascript", :src => src})
  end

  def css_tag(src, options={})
    digest = digest_for("#{src}.css")

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.css"

    content_tag :link, "", options.merge({:rel => "stylesheet", :href => src})
  end

  private

  def digest_for(logical_path)
    digest = CACHE_ASSETS && ASSETS.digest_list && ASSETS.digest_list[logical_path]

    digest = ASSETS[logical_path].digest if digest.blank?

    raise "Cannot find file: " + logical_path if digest.blank?

    return digest
  end

end
