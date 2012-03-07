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
    end
  end
end
