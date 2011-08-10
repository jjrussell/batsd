class OneOffs
  def self.assign_employee_user_roles
    UserRole.all.each do |role|
      role.employee = role.name != 'agency'
      role.save!
    end
  end
end
