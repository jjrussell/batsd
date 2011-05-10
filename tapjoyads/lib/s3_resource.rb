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
    rescue RightAws::AwsError => e
      if e.message =~ /^NoSuchKey:/
        nil
      else
        raise e
      end
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
          convert_from_raw_attributes(S3.bucket(bucket_name).get(id))
        end
      else
        @saved_attributes = convert_from_raw_attributes(S3.bucket(bucket_name).get(id))
      end
      @attributes = @saved_attributes.dup
    end
    self
  end
  
  def reload(load_from_memcache = true)
    load({ :load_from_memcache => load_from_memcache })
  end
  
  def save(options = {})
    catch_exceptions = options.delete(:catch_exceptions) { true }
    save_to_memcache = options.delete(:save_to_memcache) { true }
    raise "Unknown options #{options.keys.join(', ')}"    unless options.empty?
    raise "Can't save #{self.class} without a BucketName" unless bucket_name.present?
    raise "Can't save #{self.class} without an ID"        unless id.present?
    
    now = Time.zone.now
    self.created_at = now if new_record?
    self.updated_at = now
    
    raw_attributes = convert_to_raw_attributes(@attributes)
    begin
      Mc.put(get_memcache_key, @attributes) if save_to_memcache
      
      s3 = RightAws::S3.new(nil, nil, { :multi_thread => true, :port => 80, :protocol => 'http' })
      bucket = RightAws::S3::Bucket.new(s3, bucket_name)
      bucket.put(id, raw_attributes)
      
      @saved_attributes = @attributes.dup
      @unsaved_attributes.clear
      return true
    rescue Exception => e
      if e.is_a?(RightAws::AwsError)
        Mc.increment_count("failed_s3_saves.s3.#{bucket_name}.#{(now.to_f / 1.hour).to_i}", false, 1.day)
      else
        Mc.increment_count("failed_s3_saves.mc.#{bucket_name}.#{(now.to_f / 1.hour).to_i}", false, 1.day)
      end
      
      if catch_exceptions
        # uuid = UUIDTools::UUID.random_create.to_s
        # bucket = S3.bucket(BucketNames::SOME_BUCKET)
        # bucket.put("incomplete/#{uuid}", raw_attributes)
        # message = { :id => id, :class => self.class.to_s, :uuid => uuid }.to_json
        # Sqs.send_message(QueueNames::SOME_QUEUE, message)
        return false
      else
        raise e
      end
    end
  end
  
  def save!(options = {})
    save(options.merge({ :catch_exceptions => false }))
  end
  
  def save_in_background(options = {})
    Thread.new(options) do |opts|
      save(opts)
    end
  end
  
  def destroy
    Mc.delete(get_memcache_key)
    S3.bucket(bucket_name).key(id).delete
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
    return value if @attributes[attribute] == value
    
    if value.nil?
      @attributes.delete(attribute)
    else
      @attributes[attribute] = value
    end
    @unsaved_attributes << attribute
    @attributes[attribute]
  end
  
  def convert_to_raw_attributes(attributes)
    string_attributes = {}
    attributes.each do |k, v|
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
  
end
