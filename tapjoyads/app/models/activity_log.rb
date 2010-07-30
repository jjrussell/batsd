class ActivityLog < SimpledbResource
  self.domain_name = 'activity_logs'
  
  self.sdb_attr :user
  self.sdb_attr :controller
  self.sdb_attr :action
  self.sdb_attr :request_id
  self.sdb_attr :object_id
  self.sdb_attr :object_type
  self.sdb_attr :before_state, :type => :json
  self.sdb_attr :after_state,  :type => :json
  self.sdb_attr :created_at,   :type => :time, :attr_name => 'updated-at'
  
  def initialize(options = {})
    @state_object = nil
    
    super({ :load_from_memcache => false }.merge(options))
  end
  
  def object
    return @state_object unless @state_object.nil?
    
    klass = self.object_type.constantize
    if klass.respond_to?(:sdb)
      @state_object = klass.new(:key => self.object_id)
    else
      @state_object = klass.find(self.object_id)
    end
    @state_object
  end
  
  def object=(obj)
    @state_object = obj
    self.object_id = obj.id
    self.object_type = obj.class.to_s
    self.before_state = obj.attributes
  end
  
  def finalize_states
    self.after_state = @state_object.attributes
    after_hash = self.after_state
    before_hash = self.before_state
    
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
    if after_hash.length == 1 && (after_hash['updated_at'] || after_hash['updated-at'])
      after_hash = {}
    end
    
    self.before_state = before_hash
    self.after_state = after_hash
  end
  
  def serial_save(options = {})
    return unless is_new
    
    if self.before_state.length > 0 || self.after_state.length > 0
      super({ :write_to_memcache => false }.merge(options))
    end
  end
  
end
