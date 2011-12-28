class SimpledbShardedResource < SimpledbResource

  def self.all_domain_names
    (0...num_domains).collect { |num| "#{name.tableize}_#{num}" }
  end

  def self.count(options = {})
    if options[:domain_name]
      super(options)
    else
      where      = options.delete(:where)
      consistent = options.delete(:consistent)
      raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

      hydra = Typhoeus::Hydra.new
      count = 0

      all_domain_names.each do |current_domain_name|
        SimpledbResource.count_async(:domain_name => current_domain_name, :where => where, :hydra => hydra, :consistent => consistent) do |c|
          count += c
        end
      end

      hydra.run
      count
    end
  end

  def self.select_all(options = {}, &block)
    conditions = options.delete(:conditions)
    consistent = options.delete(:consistent)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    records = []
    select_options = { :where => conditions, :consistent => consistent }
    all_domain_names.each do |current_domain_name|
      select_options[:domain_name] = current_domain_name
      select(select_options.dup) do |record|
        block_given? ? yield(record) : records << record
      end
    end

    records
  end


  private

  def self.num_domains
    @num_domains ||= 0
  end

  def self.num_domains=(num)
    @num_domains = num
  end

end
