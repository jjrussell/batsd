class OneOffs

  def self.create_partner_changer_role
    UserRole.create!(:name => 'partner_changer', :employee => true)
  end

end
