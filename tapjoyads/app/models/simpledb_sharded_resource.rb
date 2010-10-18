class SimpledbShardedResource < SimpledbResource
  
  def self.all_domain_names
    (0...num_domains).collect { |num| "#{name.tableize}_#{num}" }
  end
  
  def self.count(options = {})
    if options[:domain_name]
      super(options)
    else
      where = options.delete(:where)
      retries = options.delete(:retries) { 10 }
      raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
      
      all_domain_names.inject(0) do |sum, current_domain_name|
        sum + SimpledbResource.count(:domain_name => current_domain_name, :where => where, :retries => retries)        
      end
    end
  end
  
  private
  
  def self.num_domains  
    @@num_domains ||= 0
  end
  
  def self.num_domains=(num)
    @@num_domains = num
  end
  
end
