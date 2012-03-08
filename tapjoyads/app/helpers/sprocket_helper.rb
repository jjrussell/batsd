module SprocketHelper
  def js_tag(src, options={})
    attributes = create_attributes(options)

    begin
      digest = ASSETS["#{src}.js"].digest
    rescue
      raise "Error reading js: #{src}"
    end

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.js"
    "<script type='text/javascript' #{attributes} src='#{src}'></script>"
  end

  def css_tag(src, options={})
    attributes = create_attributes(options)

    begin
      digest = ASSETS["#{src}.css"].digest
    rescue
      raise "Error reading css: #{src}"
    end

    src = "#{ASSET_HOST}/assets/#{src}-#{digest}.css"

    "<link rel='stylesheet' #{attributes} href='#{src}' />"
  end

  private
  def create_attributes(options)
    options.map { |k, v| "#{k}='#{v}'" }.join " "
  end
end
