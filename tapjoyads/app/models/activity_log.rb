class ActivityLog < SimpledbResource
  self.domain_name = 'activity_logs'
  
  self.sdb_attr :user
  self.sdb_attr :controller
  self.sdb_attr :action
  self.sdb_attr :created_at, :type => :time, :attr_name => 'updated-at'
  
  def initialize(options = {})
    @state_objects = []
    
    super({ :load_from_memcache => false }.merge(options))
    
    setup_accessors unless is_new
  end
  
  def add_state_object(object)
    self.put("object_id_#{@state_objects.length}", object.id)
    self.put("object_type_#{@state_objects.length}", object.class.to_s)
    self.put("object_before_state_#{@state_objects.length}", object.attributes, { :type => :json })
    @state_objects << object
  end
  
  def finalize_states
    @state_objects.each_with_index do |object, i|
      self.put("object_after_state_#{i}", object.attributes, { :type => :json })
      after_hash = self.get("object_after_state_#{i}", { :type => :json })
      before_hash = self.get("object_before_state_#{i}", { :type => :json })
      
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
      
      self.put("object_before_state_#{i}", before_hash, { :type => :json })
      self.put("object_after_state_#{i}", after_hash, { :type => :json })
    end
  end
  
  def serial_save(options = {})
    return unless is_new
    
    @state_objects.length.times do |i|
      if self.get("object_before_state_#{i}", { :type => :json }).length > 0 || self.get("object_after_state_#{i}", { :type => :json }).length > 0
        super({ :write_to_memcache => false }.merge(options))
        return
      end
    end
  end
  
private
  
  def setup_accessors
    25.times do |i|
      if self.get("object_id_#{i}")
        ActivityLog.sdb_attr("object_id_#{i}")
        ActivityLog.sdb_attr("object_type_#{i}")
        ActivityLog.sdb_attr("object_before_state_#{i}", { :type => :json })
        ActivityLog.sdb_attr("object_after_state_#{i}",  { :type => :json })
        
        klass = self.get("object_type_#{i}").constantize
        if klass.respond_to?(:sdb)
          @state_objects << klass.new(:key => self.get("object_id_#{i}"))
        else
          @state_objects << klass.find(self.get("object_id_#{i}"))
        end
        
        self.class.class_eval <<-"end_eval", __FILE__, __LINE__
          def object_#{i}
            @state_objects[#{i}]
          end
        end_eval
      else
        break
      end
    end
  end
  
end
