module ConsoleSecurity::PermissionGroup
  def self.included(model)
    model.class_eval do
      has_many :permissions, :foreign_key => 'group_id'
      attr_accessible :name
      validates :name, :presence => true
    end
  end
end
