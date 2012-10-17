module SprocketHelper
  def js_tag(src)
    warn 'js_tag is deprecated. Use javascript_include_tag'
    javascript_include_tag src
  end

  def css_tag(src)
    warn 'css_tag is deprecated. Use stylesheet_link_tag'
    stylesheet_link_tag src
  end

  def embed_js(src)
    javascript_include_tag src
  end

  def js_cache(src, first=false)
    val = path_to_javascript(src)
    first ? js_requires.unshift(val) : js_requires << val
  end

  def css_cache(src, first=false)
    val = path_to_stylesheet(src)
    first ? css_requires.unshift(val) : css_requires << val
  end

  def js_cache!(src, first=false)
    first ? js_requires.unshift(src) : js_requires << src
  end

  def js_requires
    @js_requires ||= []
  end

  def css_requires
    @css_requires ||= []
  end
end
