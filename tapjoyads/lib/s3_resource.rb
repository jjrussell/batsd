class S3Resource

  superclass_delegating_accessor :bucket_name
  @@attribute_types = {}
  attr_accessor :id
  attr_reader :attributes

  def self.attribute(attribute, options = {})
    type    = options.delete(:type) { :string }
    default = options.delete(:default)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Unknown type conversion: #{type}"           unless TypeConverters::TYPES.include?(type)

    @@attribute_types[attribute.to_s] = type

    module_eval %Q{
      def #{attribute}
        read_attribute('#{attribute}', #{default.inspect})
      end
    }

    module_eval %Q{
      def #{attribute}=(value)
        write_attribute('#{attribute}', value)
      end
    }

    module_eval %Q{
      def #{attribute}?
        read_attribute('#{attribute}', #{default.inspect}).present?
      end
    }

    module_eval %Q{
      def #{attribute}_changed?
        @unsaved_attributes.include?('#{attribute}')
      end
    }

    module_eval %Q{
      def #{attribute}_was
        @saved_attributes['#{attribute}']
      end
    }
  end
  self.attribute(:created_at, { :type => :time })
  self.attribute(:updated_at, { :type => :time })

  def self.find(id, options = {})
    load_from_memcache = options.delete(:load_from_memcache) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    object = self.new(:id => id)
    object.load({ :load_from_memcache => load_from_memcache })
  end

  def self.find_by_id(id, options = {})
    begin
      find(id, options)
    rescue AWS::S3::Errors::NoSuchKey => e
      nil
    end
  end

  def self.find_or_initialize_by_id(id, options = {})
    object = find_by_id(id, options)
    if object.nil?
      object = self.new(:id => id)
    end
    object
  end

  def initialize(options = {})
    @id = options.delete(:id) { UUIDTools::UUID.random_create.to_s }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    @attributes         = {}
    @saved_attributes   = {}
    @unsaved_attributes = Set.new
  end

  def new_record?
    @saved_attributes.empty?
  end

  def changed?
    @unsaved_attributes.present?
  end

  def load(options = {})
    load_from_memcache = options.delete(:load_from_memcache) { true }
    raw_attributes     = options.delete(:raw_attributes)
    raise "Can't load #{self.class} without a BucketName" unless bucket_name.present?
    raise "Can't load #{self.class} without an ID"        unless id.present?

    @saved_attributes.clear
    @unsaved_attributes.clear

    if raw_attributes.present?
      @attributes = convert_from_raw_attributes(raw_attributes)
      @unsaved_attributes += @attributes.keys
    else
      if load_from_memcache
        @saved_attributes = Mc.get_and_put(get_memcache_key) do
          request_with_retries do
            raw_attributes = S3.bucket(bucket_name).objects[id].read
          end
          convert_from_raw_attributes(raw_attributes)
        end
      else
        request_with_retries do
          raw_attributes = S3.bucket(bucket_name).objects[id].read
        end
        @saved_attributes = convert_from_raw_attributes(raw_attributes)
      end
      @attributes = @saved_attributes.dup
    end
    self
  end

  def reload(load_from_memcache = true)
    load({ :load_from_memcache => load_from_memcache })
  end

  def save(options = {})
    begin
      save!(options)
    rescue
      false
    end
  end

  def save!(options = {})
    save_to_memcache = options.delete(:save_to_memcache) { true }
    retries = options.delete(:retries) { 5 }
    raise "Unknown options #{options.keys.join(', ')}"    unless options.empty?
    raise "Can't save #{self.class} without a BucketName" unless bucket_name.present?
    raise "Can't save #{self.class} without an ID"        unless id.present?

    unless @unsaved_attributes.empty?
      now = Time.zone.now
      self.created_at = now if new_record?
      self.updated_at = now

      Mc.put(get_memcache_key, @attributes) if save_to_memcache

      raw_attributes = convert_to_raw_attributes

      request_with_retries(retries) do
        S3.bucket(bucket_name).objects[id].write(:data => raw_attributes)
      end

      @saved_attributes = @attributes.dup
      @unsaved_attributes.clear
    end
    true
  end

  def destroy
    Mc.delete(get_memcache_key)
    request_with_retries do
      S3.bucket(bucket_name).objects[id].delete
    end
    @saved_attributes.clear
    @unsaved_attributes.clear
    @unsaved_attributes += @attributes.keys
    self
  end

  private

  def read_attribute(attribute, default = nil)
    @attributes[attribute] || default
  end

  def write_attribute(attribute, value)
    if value.nil?
      @attributes.delete(attribute)
    else
      @attributes[attribute] = value
    end
    @unsaved_attributes << attribute
    @attributes[attribute]
  end

  def convert_to_raw_attributes
    string_attributes = {}
    @attributes.each do |k, v|
      type = @@attribute_types[k] || :string
      string_attributes[k] = TypeConverters::TYPES[type].to_string(v)
    end
    string_attributes.to_json
  end

  def convert_from_raw_attributes(raw_attributes)
    attributes = {}
    string_attributes = JSON.parse(raw_attributes)
    string_attributes.each do |k, v|
      type = @@attribute_types[k] || :string
      attributes[k] = TypeConverters::TYPES[type].from_string(v)
    end
    attributes
  end

  def get_memcache_key
    "s3.#{bucket_name}.#{id}"
  end

  def request_with_retries(retries = 5, &block)
    begin
      yield
    rescue Exception => e
      retries = 0 if e.is_a?(AWS::S3::Errors::NoSuchKey)
      Rails.logger.info("S3Resource: request failed, will retry #{retries} more times. #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
      if retries > 0
        delay ||= 0.1
        retries -= 1
        sleep(delay)
        delay *= 2
        retry
      else
        raise e
      end
    end
  end

end
