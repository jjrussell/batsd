require 'digest/md5'
module I18n
  module Backend
    module Base
      def load_yml(filepath)
        File.open( filepath ) do |f|
          tmp=f.gets
          if tmp.match /^\357\273\277/
            f.seek 3
          else
            f.seek 0
          end
          YAML.load( f )
        end
      end

      def load_file(filename)
        type = File.extname(filename).tr('.', '').downcase
        raise UnknownFileType.new(type, filename) unless respond_to?(:"load_#{type}", true)
        data = send(:"load_#{type}", filename)
        hash = load_hash(filename)
        raise InvalidLocaleData.new(filename) unless data.is_a?(Hash)
        data.each { |locale, d| store_translations(locale, d.merge({:hash=>hash}) || {}) }
      end

      def load_hash(filename)
        File.open(filename) {|f| Digest::MD5.hexdigest(f.read) }

      end
    end
  end
end
