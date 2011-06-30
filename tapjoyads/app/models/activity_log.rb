class ActivityLog < SimpledbResource
  self.domain_name = 'activity_logs'
  
  self.sdb_attr :user
  self.sdb_attr :controller
  self.sdb_attr :action
  self.sdb_attr :request_id
  self.sdb_attr :object_id
  self.sdb_attr :object_type
  self.sdb_attr :included_methods,  :force_array => true
  self.sdb_attr :partner_id
  self.sdb_attr :before_state,      :type => :json
  self.sdb_attr :after_state,       :type => :json
  self.sdb_attr :created_at,        :type => :time, :attr_name => 'updated-at'

  SKIP_KEYS = %w(updated-at updated_at perishable_token)

  def initialize(options = {})
    @state_object = nil
    @state_object_new = false

    super({ :load_from_memcache => false }.merge(options))
  end

  def diff_keys
    (before_state.keys | after_state.keys) - SKIP_KEYS
  end

  def diff_value(key)
    Differ.diff_by_word(after_state[key].to_s, before_state[key].to_s)
  end

  def object_name
    if object.respond_to?(:name_with_suffix)
      object.name_with_suffix
    elsif object.respond_to?(:name)
      object.name
    else
      "#{object_id[0..6]}..."
    end
  end

  def object
    return @state_object unless @state_object.nil?
    
    klass = self.object_type.constantize
    if klass.respond_to?(:sdb)
      @state_object = klass.new(:key => self.object_id)
    else
      @state_object = klass.find_by_id(self.object_id)
    end
    @state_object_new = false
    @state_object
  end
  
  def object=(obj)
    @state_object = obj
    @state_object_new = obj.new_record?
    self.before_state = get_attributes
  end

  def included_methods=(methods)
    methods.each do |method|
      self.put('included_methods', method, :replace => false)
    end
  end

  def finalize_states
    self.object_id = @state_object.id
    self.object_type = @state_object.class.to_s
    self.after_state = get_attributes

    if @state_object.respond_to?(:partner_id)
      self.partner_id = @state_object.partner_id
    elsif self.object_type == 'Partner'
      self.partner_id = self.object_id
    end
    
    before_hash = {}
    after_hash = {}
    
    if @state_object_new
      after_hash = self.after_state
    else
      before_hash = self.before_state
      after_hash = self.after_state
      
      after_hash.reject! do |k, v|
        if before_hash[k] == v
          before_hash.delete(k)
          true
        else
          false
        end
      end
      
      if before_hash.length == 1 && (before_hash['updated_at'] || before_hash['updated-at'])
        before_hash = {}
      end
    end
    
    if after_hash.length == 1 && (after_hash['updated_at'] || after_hash['updated-at'])
      after_hash = {}
    end

    self.before_state = before_hash
    self.after_state = after_hash
  end
  
  def serial_save(options = {})
    return unless is_new
    return if self.object.respond_to?(:errors) && self.object.errors.is_a?(ActiveRecord::Errors) && self.object.errors.present?
    
    if self.before_state.length > 0 || self.after_state.length > 0
      super({ :write_to_memcache => false }.merge(options))
    end
  end
  
private

  def get_attributes
    attrs = @state_object.attributes
    self.included_methods.each do |method|
      attrs[method.to_s] = @state_object.send(method.to_sym).inspect
    end
    attrs.each do |k, v|
      attrs[k] = v.utc if v.respond_to?(:utc)
    end

    attrs
  end
end
