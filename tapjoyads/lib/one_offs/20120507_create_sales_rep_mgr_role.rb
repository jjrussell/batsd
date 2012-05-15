class OneOffs

  def self.create_partner_changer_role
    UserRole.create!(:name => 'sales_rep_mgr', :employee => true)
  end

end
