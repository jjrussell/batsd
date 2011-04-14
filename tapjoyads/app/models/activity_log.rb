class ActivityLog < SimpledbResource
  self.domain_name = 'activity_logs'
  
  self.sdb_attr :user
  self.sdb_attr :controller
  self.sdb_attr :action
  self.sdb_attr :request_id
  self.sdb_attr :object_id
  self.sdb_attr :object_type
  self.sdb_attr :associated_id
  self.sdb_attr :associated_type
  self.sdb_attr :partner_id
  self.sdb_attr :before_state, :type => :json
  self.sdb_attr :after_state,  :type => :json
  self.sdb_attr :created_at,   :type => :time, :attr_name => 'updated-at'
  
  def initialize(options = {})
    @state_object = nil
    @state_object_new = false
    
    super({ :load_from_memcache => false }.merge(options))
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
    self.before_state = fix_time_zones(obj.attributes)
  end

  def associated
    return @state_associated unless @state_associated.nil?

    klass = self.associated_type.constantize
    if klass.respond_to?(:sdb)
      @state_associated = klass.new(:key => self.associated_id)
    else
      @state_associated = klass.find_by_id(self.associated_id)
    end
    @state_associated_new = false
    @state_associated
  end

  def associated=(assoc)
    @state_associated = assoc
    @state_associated_new = assoc.new_record?
    @associated_before_state = fix_time_zones(assoc.attributes)
  end

  def finalize_states
    self.object_id = @state_object.id
    self.object_type = @state_object.class.to_s
    self.after_state = fix_time_zones(@state_object.attributes)
    
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

    unless @state_associated.nil?
      self.associated_id = @state_associated.id
      self.associated_type = @state_associated.class.to_s
      associated_key_name = "associated #{self.associated_type.underscore}"
      if @state_associated_new
        before_hash[associated_key_name] = {}
        after_hash[associated_key_name] = @state_associated.attributes
      else
        before_hash[associated_key_name] = @associated_before_state
        begin
          after_hash[associated_key_name] = @state_associated.reload.attributes
          after_hash[associated_key_name].reject! do |k, v|
            if before_hash[associated_key_name][k] == v
              before_hash[associated_key_name].delete(k)
              true
            else
              false
            end
          end
        rescue ActiveRecord::RecordNotFound
          after_hash[associated_key_name] = {}
        end

        if before_hash[associated_key_name].length == 1 && (before_hash[associated_key_name]['updated_at'] || before_hash[associated_key_name]['updated-at'])
          before_hash[associated_key_name] = {}
        end
      end

      if after_hash[associated_key_name].length == 1 && (after_hash[associated_key_name]['updated_at'] || after_hash[associated_key_name]['updated-at'])
        after_hash[associated_key_name] = {}
      end
      before_hash[associated_key_name] = before_hash[associated_key_name].to_json
      after_hash[associated_key_name] = after_hash[associated_key_name].to_json
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
  
  def fix_time_zones(attrs)
    attrs.each do |k, v|
      attrs[k] = v.utc if v.respond_to?(:utc)
    end
    attrs
  end
  
end
