class OneOffs
  
  def self.copy_instructions_into_offers
    ActionOffer.find_each do |action_offer|
      offer = action_offer.primary_offer
      offer.instructions = action_offer.instructions
      offer.url = action_offer.app.direct_store_url
      offer.save!
    end
  end

  def self.copy_ranks_to_s3(start_time_string=nil, end_time_string=nil, granularity_string='hourly')
    start_time, end_time, granularity = Appstats.parse_dates(start_time_string, end_time_string, granularity_string)
    if granularity == :daily
      date_format = ('%Y-%m')
      incrementer = 1.month
    else
      date_format = ('%Y-%m-%d')
      incrementer = 1.day
    end

    time = start_time
    while time <= end_time
      copy_ranks(time.strftime(date_format))
      time += incrementer
    end
  end

  def self.copy_ranks(date_string)
    Stats.select(:where => "itemName() like 'app.#{date_string}.%'") do |stats|
      puts stats.key
      ranks_key = stats.key.gsub('app', 'ranks').gsub('.', '/')
      ranks = S3Stats::Ranks.find_or_initialize_by_id(ranks_key)
      stats.parsed_ranks.each do |key, value|
        ranks.all_ranks ||= {}
        ranks.all_ranks[key] = value
      end
      ranks.save!
    end
  end

  def self.delete_ranks_from_sdb(start_time_string=nil, end_time_string=nil, granularity_string='hourly')
    start_time, end_time, granularity = Appstats.parse_dates(start_time_string, end_time_string, granularity_string)
    if granularity == :daily
      date_format = ('%Y-%m')
      incrementer = 1.month
    else
      date_format = ('%Y-%m-%d')
      incrementer = 1.day
    end

    time = start_time
    while time <= end_time
      delete_ranks(time.strftime(date_format))
      time += incrementer
    end
  end

  def self.delete_ranks(date_string)
    Stats.select(:where => "itemName() like 'app.#{date_string}.%'") do |stats|
      stats.delete('ranks')
      stats.serial_save
    end
  end
end
