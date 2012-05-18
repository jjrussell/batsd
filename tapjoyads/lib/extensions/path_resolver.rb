class ActionView::PathResolver

  private

    def query(path, exts, formats)
      query = escape_entry File.join(@path, path)

      exts.each do |ext|
        query << '{' << ext.map {|e| e && ".#{e}" }.join(',') << ',}'
      end

      query.gsub!(/\{\.html,/, "{.html,.text.html,")
      query.gsub!(/\{\.text,/, "{.text,.text.plain,")
      query.gsub!(/,\.text,/, ",.text,.text.plain,") # added

      templates = []
      sanitizer = Hash.new { |h,k| h[k] = Dir["#{File.dirname(k)}/*"] }

      Dir[query].each do |p|
        next if File.directory?(p) || !sanitizer[p].include?(p)

        handler, format = extract_handler_and_format(p, formats)
        contents = File.open(p, "rb") {|io| io.read }

        # original:
        # templates << Template.new(contents, File.expand_path(p), handler,
        #          :virtual_path => path, :format => format)
        templates << ActionView::Template.new(contents, File.expand_path(p), handler,
          :virtual_path => path, :format => format)
      end

      templates
    end

end
