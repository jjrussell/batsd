class OneOffs

  def self.create_default_app_group
    raise "Default AppGroup already exists" if AppGroup.count > 0
    app_group = AppGroup.create(:name => 'default', :conversion_rate => 1, :bid => 1, :price => -1, :avg_revenue => 5, :random => 1, :over_threshold => 6)
    App.connection.execute("UPDATE apps SET app_group_id = '#{app_group.id}'")
  end

end
