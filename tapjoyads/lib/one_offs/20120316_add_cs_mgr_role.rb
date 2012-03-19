class OneOffs
  def self.add_cs_mgr_role
    ra = UserRole.new :name => 'customer_service_manager', :employee => '1'
    ra.save!
  end
end
