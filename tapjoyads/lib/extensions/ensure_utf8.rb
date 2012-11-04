# encoding: utf-8
if defined?(Encoding)

  module EnsureUtf8
    module Common

      def is_utf8_encoded?
        @is_utf8_encoded ||=false
      end

      def ensure_utf8_encoding!
        unless self.is_utf8_encoded?
          @is_utf8_encoded = true
          instance_variables.each do |ivar_sym|
            v = instance_variable_get(ivar_sym)
            instance_variable_set(ivar_sym, v.ensure_utf8_encoding!) if v.respond_to?(:ensure_utf8_encoding!)
          end
        end
        self
      end
    end
  end

  class Array
    def is_utf8_encoded?
      @is_utf8_encoded ||=false
    end

    def ensure_utf8_encoding!
      return if is_utf8_encoded?
      @is_utf8_encoded=true
      each_with_index do |v, k|
        if (v.is_a?(String))
          self[k] = String.new(v).ensure_utf8_encoding!
        else
          v.ensure_utf8_encoding! if v.respond_to?(:ensure_utf8_encoding!)
        end
      end
      self
    end

  end

  class Hash
    def is_utf8_encoded?
      @is_utf8_encoded ||=false
    end

    def ensure_utf8_encoding!
      return if is_utf8_encoded?
      @is_utf8_encoded=true
      keys.each do |k|
        v= self[k]
        v = String.new(v) if v.is_a?(String) && v.encoding.name!=Encoding::UTF_8.name
        v.ensure_utf8_encoding! if v.respond_to?(:ensure_utf8_encoding!)
        k = String.new(k).ensure_utf8_encoding! if k.is_a?(String) && k.encoding.name!=Encoding::UTF_8.name
        self.delete k
        self[k] = v
      end
      self
    end
  end

  class String
    def ensure_utf8_encoding!
      self.force_encoding('UTF-8')
    end
  end

  ActiveRecord::Base.send(:include, EnsureUtf8::Common)

end

module Marshal
  def restore_with_ensure_utf8(*opts)
    res = load(*opts)
    res.ensure_utf8_encoding! if res.respond_to?( :ensure_utf8_encoding! ) && defined?( Encoding )
    res
  end

  alias_method :load_with_ensure_utf8, :restore_with_ensure_utf8
  module_function :restore_with_ensure_utf8, :load_with_ensure_utf8
end