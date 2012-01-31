class SyslogMessage

  CGI_ESCAPED_PREFIX = '^^TAPJOY_ESCAPED^^'

  attr_reader :id, :attributes

  def self.define_attr(name, options = {})
    type        = options.delete(:type)        { :string }
    cgi_escape  = options.delete(:cgi_escape)  { false }
    force_array = options.delete(:force_array) { false }
    replace     = options.delete(:replace)     { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    module_eval %Q{
      def #{name}
        if @attributes[#{name.inspect}].nil?
          #{force_array} ? [] : nil
        else
          values = @attributes[#{name.inspect}].map do |value|
            value = CGI::unescape(value.gsub('#{CGI_ESCAPED_PREFIX}', '')) if value.starts_with?('#{CGI_ESCAPED_PREFIX}')
            TypeConverters::TYPES[#{type.inspect}].from_string(value)
          end
          values.size == 1 && !#{force_array} ? values.first : values
        end
      end
    }

    module_eval %Q{
      def #{name}=(value)
        return if value.nil?
        value = TypeConverters::TYPES[#{type.inspect}].to_string(value)
        if value.present?
          value.gsub!(/\n|\r|\t/, '')
          value = "#{CGI_ESCAPED_PREFIX}\#{CGI::escape(value)}" if #{cgi_escape}
          if #{replace}
            @attributes[#{name.inspect}] = [ value ]
          else
            @attributes[#{name.inspect}] ||= []
            @attributes[#{name.inspect}] << value
          end
        end
      end
    }

    module_eval %Q{
      def #{name}?
        @attributes[#{name.inspect}].present?
      end
    }
  end

  self.define_attr :time, :type => :time
  self.define_attr :path, :force_array => true, :replace => false
  self.define_attr :user_agent, :cgi_escape => true
  self.define_attr :ip_address
  self.define_attr :geoip_country

  def initialize(options = {})
    @attributes = {}
    @id         = options.delete(:id)   || UUIDTools::UUID.random_create.to_s
    self.time   = options.delete(:time) || Time.zone.now
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
  end

  def save
    @attributes['updated-at'] = [ Time.zone.now.to_f.to_s ]
    begin
      SYSLOG_NG_LOGGER << to_json
    rescue Exception => e
      Notifier.alert_new_relic(e.class, e.message)
    end
  end

  def to_json
    { :key => @id, :attrs => @attributes }.to_json
  end

end
