class OneOffs

  def self.create_file_sharer_role
    UserRole.create!(:name => 'file_sharer', :employee => true)
  end

end
