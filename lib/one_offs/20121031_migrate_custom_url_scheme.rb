class OneOffs

   def self.migrate_custom_url_scheme
     App.connection.execute("UPDATE apps SET protocol_handler = custom_url_scheme WHERE custom_url_scheme <> '';")
     App.connection.execute("UPDATE apps SET custom_url_scheme = NULL;")
  end
end
