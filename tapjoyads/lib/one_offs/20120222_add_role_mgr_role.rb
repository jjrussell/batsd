class OneOffs
  def self.add_role_admin_role
    ra = UserRole.new :name => 'role_admin', :employee = '1'
    ra.save!
  end
end
