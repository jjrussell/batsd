module SprocketHelper
  def js_tag(src, options={})
    asset = ASSETS["#{src}.js"]

    raise "Cannot find js file: #{src}.js" if asset.blank?

    digest = asset.digest

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.js"
    options.merge!({:type => "text/javascript", :src => src})

    content_tag :script, "", options
  end

  def css_tag(src, options={})
    asset = ASSETS["#{src}.css"]

    raise "Cannot find js file: #{src}.js" if asset.blank?

    digest = asset.digest

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.css"
    options.merge!({:rel => "stylesheet", :href => src})

    content_tag :link, "", options
  end

end
