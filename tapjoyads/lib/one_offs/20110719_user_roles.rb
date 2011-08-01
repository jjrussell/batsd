class OneOffs
  def self.assign_employee_user_roles
    UserRole.all.each do |role|
      role.employee = (role.name == 'agency' ? false : true)
      role.save!
    end
  end
end
