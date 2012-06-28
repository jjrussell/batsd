class OneOffs

  def self.fix_partner_names
    Partner.update_all( "name = '-'", "name = '' or name is null" )
  end

end
