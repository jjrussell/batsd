class OneOffs

  def self.copy_ranks_to_s3(start_time_string=nil, end_time_string=nil, granularity_string='hourly')
    start_time, end_time, granularity = Appstats.parse_dates(start_time_string, end_time_string, granularity_string)
    if granularity_string == 'daily'
      date_format = ('%Y-%m')
      incrementer = 1.month
    else
      date_format = ('%Y-%m-%d')
      incrementer = 1.day
    end

    time = start_time
    while time < end_time
      copy_ranks(time.strftime(date_format))
      time += incrementer
    end
  end
  
  def self.copy_ranks(date_string)
    Stats.select(:where => "itemName() like 'app.#{date_string}.%'") do |stats|
      puts stats.key
      ranks_key = stats.key.gsub('app', 'ranks').gsub('.', '/')
      ranks = {}
      stats.parsed_ranks.each do |key, value|
        ranks[key] = value
      end
      unless ranks.empty?
        s3_ranks = S3Stats::Ranks.find_or_initialize_by_id(ranks_key)
        s3_ranks.all_ranks = ranks
        s3_ranks.save!
      end
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
    while time < end_time
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

  def self.aggregate_global_platform_stats(date = nil)
    date ||= Time.zone.now.beginning_of_day
    puts "starting aggregation for #{date}"
    num_unverified = Offer.count(:conditions => [ "last_daily_stats_aggregation_time < ?",  date.beginning_of_day ])
    if num_unverified > 0
      puts "there are #{num_unverified} offers with unverified stats, not aggregating global stats yet for #{date}"
    else
      StatsAggregation.aggregate_hourly_group_stats(date, true)
    end
    puts "done aggregating for #{date}"
  end

  def self.aggregate_all_global_platform_stats(date = nil)
    date ||= Time.zone.parse('2009-09-01')
    while date < Time.zone.now
      aggregate_global_platform_stats(date)
      date += 1.day
    end
  end

end

