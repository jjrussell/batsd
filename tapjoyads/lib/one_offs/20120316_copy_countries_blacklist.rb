class OneOffs
  def self.copy_countries_blacklist
    counter = 0
    App.find_each(:conditions => "countries_blacklist is not null and countries_blacklist <> '[]' and countries_blacklist <> ''") do |app|
      counter += 1
      app.primary_app_metadata.countries_blacklist = app.read_attribute(:countries_blacklist)
      app.primary_app_metadata.save!
    end
    puts "Processed #{counter} apps."
  end
end
