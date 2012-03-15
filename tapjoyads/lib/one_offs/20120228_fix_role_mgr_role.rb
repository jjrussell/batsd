class OneOffs
  def self.fix_role_mgr_role
    rm = UserRole.find_by_name('role_admin')
    if rm
      rm.name = 'role_mgr'
      rm.save!
    end
  end
end
