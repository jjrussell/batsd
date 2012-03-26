# modified version of Compass helper functions
# https://github.com/chriseppstein/compass/blob/stable/lib/compass/sass_extensions/functions/inline_image.rb
module Sprockets::Tj::Helpers
  def inline_image(path, mime_type = nil)
    path = path.value

    real_path = File.join("public/", path)
    val = data(real_path)
    inline_image_string(val, compute_mime_type(path, mime_type))
  end

  def inline_font_files(*args)
    raise Sass::SyntaxError, "An even number of arguments must be passed to font_files()" unless args.size % 2 == 0
    files = []
    while args.size > 0
      path = args.shift.value
      real_path = File.join("public/fonts", path)
      url = inline_image_string(data(real_path), compute_mime_type(path))
      files << "#{url} format('#{args.shift}')"
    end
    Sass::Script::String.new(files.join(", "))
  end

protected
  def inline_image_string(data, mime_type)
    data = [data].flatten.pack('m').gsub("\n","")
    url = "url('data:#{mime_type};base64,#{data}')"
    Sass::Script::String.new(url)
  end

private
  def compute_mime_type(path, mime_type = nil)
    return mime_type if mime_type
    case path
    when /\.png$/i
      'image/png'
    when /\.jpe?g$/i
      'image/jpeg'
    when /\.gif$/i
      'image/gif'
    when /\.svg$/i
      'image/svg+xml'
    when /\.otf$/i
      'font/opentype'
    when /\.eot$/i
      'application/vnd.ms-fontobject'
    when /\.ttf$/i
      'font/truetype'
    when /\.woff$/i
      'application/x-font-woff'
    when /\.off$/i
      'font/openfont'
    when /\.([a-zA-Z]+)$/
      "image/#{Regexp.last_match(1).downcase}"
    else
      raise Sass::SyntaxError, "A mime type could not be determined for #{path}, please specify one explicitly."
    end
  end

  def data(real_path)
    if File.readable?(real_path)
      File.open(real_path, "rb") {|io| io.read}
    else
      raise Sass::SyntaxError, "File not found or cannot be read: #{real_path}"
    end
  end
end

# Make the functions available to Sass
module Sass
  module Script
    module Functions
      include Sprockets::Tj::Helpers
    end
  end
end
