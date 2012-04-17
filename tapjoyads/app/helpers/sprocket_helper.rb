module SprocketHelper
  def js_tag(src, options={})
    if Sprockets::Tj.combine?
      content_tag :script, "", options.merge({:type => "text/javascript", :src => path_for(src, "js")})
    else
      Sprockets::Tj.assets[src].to_a.map do |js|
        content_tag :script, "", options.merge({:type => "text/javascript", :src => path_for(js, "js")})
      end.join("\n").html_safe
    end
  end

  def css_tag(src, options={})
    if Sprockets::Tj.combine?
      content_tag :link, "", options.merge({ :rel => "stylesheet", :href => path_for(src, "css") })
    else
      Sprockets::Tj.assets[src].to_a.map do |css|
        content_tag :link, "", options.merge({ :rel => "stylesheet", :href => path_for(css, "css") })
      end.join("\n").html_safe
    end
  end

  def embed_js(src, options={})
    src_code = Sprockets::Tj.assets[src].to_s

    content_tag :script, src_code, options.merge({:type => "text/javascript"})
  end

  ['js', 'css'].each do |type|
    define_method "#{type}_cache" do |src, *first|
      @require_arrays ||= {}
      @require_arrays[type] ||= []
      val = path_for(src, type, false)

      first[0] ? @require_arrays[type].unshift(val) : @require_arrays[type] << val
    end

    define_method "#{type}_cache!" do |src, *first|
      @require_arrays ||= {}
      @require_arrays[type] ||= []
      first[0] ? @require_arrays[type].unshift(src) : @require_arrays[type] << src
    end

    define_method "#{type}_requires" do
      @require_arrays ||= {}
      @require_arrays[type] || []
    end
  end

  def all_requires
    @require_arrays ||= {}

    (@require_arrays['css'] || []).concat(@require_arrays['js'] || [])
  end

  def path_for(src, ext, use_cdn = true)
    src = src.logical_path if src.respond_to? :logical_path
    src = src.sub /\.(js|css)$/, ""
    host = use_cdn ? Sprockets::Tj.host : ''

    Rails.logger.error "Asset #{src} not in config/precompiled_assets.yml" unless Sprockets::Tj.asset_precompiled?(src)
    if Sprockets::Tj.precompile?
      "#{host}/assets/#{src}-#{Sprockets::Tj.assets[src].digest}.#{ext}"
    else
      "#{host}/assets/#{src}-#{Time.now.to_i}.#{ext}"
    end
  end
end
