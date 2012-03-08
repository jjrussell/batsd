module SprocketHelper
  def js_tag(src, options={})
    begin
      digest = ASSETS["#{src}.js"].digest
    rescue
      raise "Error reading js: #{src}"
    end

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.js"
    options.merge!({:type => "text/javascript", :src => src})

    content_tag :script, "", options
  end

  def css_tag(src, options={})
    begin
      digest = ASSETS["#{src}.css"].digest
    rescue
      raise "Error reading css: #{src}"
    end

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.css"
    options.merge!({:rel => "stylesheet", :href => src})

    content_tag :link, "", options
  end

end
