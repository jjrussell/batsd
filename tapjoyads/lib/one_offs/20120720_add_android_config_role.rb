class OneOffs
  def self.add_android_config_role
    UserRole.new( :name => 'android_distribution_config', :employee => true ).save
  end
end
