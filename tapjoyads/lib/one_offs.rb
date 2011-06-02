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

  def self.create_default_app_group
    raise "Default AppGroup already exists" if AppGroup.count > 0
    app_group = AppGroup.create(:name => 'default', :conversion_rate => 1, :bid => 1, :price => -1, :avg_revenue => 5, :random => 1, :over_threshold => 6)
    App.connection.execute("UPDATE apps SET app_group_id = '#{app_group.id}'")
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
  
  def self.queue_udid_reports
    start_time = Time.zone.parse('2010-10-01')
    end_time = Time.zone.parse('2011-06-01')
    Offer.find_each do |offer|
      next if offer.id == '2349536b-c810-47d7-836c-2cd47cd3a796' # tested with this offer so they are already complete
      puts offer.id
      s = Appstats.new(offer.id, {:start_time => start_time, :end_time => end_time, :granularity => :daily, :stat_types => ['paid_installs']})
      s.stats['paid_installs'].each_with_index do |num_installs, idx|
        if num_installs > 0
          message = {:offer_id => offer.id, :date => (start_time + idx.days).strftime('%Y-%m-%d')}.to_json
          Sqs.send_message(QueueNames::UDID_REPORTS, message)
        end
      end
    end
  end
  
end
