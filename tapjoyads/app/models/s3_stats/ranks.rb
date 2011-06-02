class S3Stats::Ranks < S3Resource
  self.bucket_name = BucketNames::STATS
  attribute :all_ranks, :type => :json, :default => {}

  def save(options = {})
    strip_zero_arrays!(all_ranks) if all_ranks
    super(options)
  end

  def save!(options = {})
    strip_zero_arrays!(all_ranks) if all_ranks
    super(options)
  end

  def update_stat_for_hour(rank_key, hour, rank)
    update_stat(rank_key, hour, rank, 24)
  end

  def update_stat_for_day(rank_key, day, rank)
    update_stat(rank_key, day, rank, 31)
  end

  def update_stat(rank_key, position, rank, length)
    # funkiness here dealing with all_ranks being a method
    temp_ranks = all_ranks
    temp_ranks[rank_key] ||= Array.new(length, 0)
    temp_ranks[rank_key][position] = rank
    self.all_ranks = temp_ranks
  end

  def populate_daily_from_hourly(hourly_ranks, day)
    hourly_ranks.all_ranks.each do |key, value|
      rank = value.reject{ |r| r == 0 }.min
      update_stat_for_day(key, day, rank)
    end
  end

  def hourly_values(rank_key)
    all_ranks[rank_key]
  end

  def self.hourly_over_time_range(app_id, start_time, end_time)
    return {} unless app_id
    time = start_time
    date = nil
    hourly_ranks_over_range = {}
    size = ((end_time - start_time) / 1.hour).ceil
    index = 0

    while time < end_time
      if date != time.strftime('%Y-%m-%d')
        date = time.strftime('%Y-%m-%d')
        ranks = S3Stats::Ranks.find_or_initialize_by_id("ranks/#{date}/#{app_id}")
      end
      ranks.all_ranks.each do |key, values|
        value = values[time.hour]
        unless value == 0
          hourly_ranks_over_range[key] ||= Array.new(size, nil)
          hourly_ranks_over_range[key][index] = value
        end
      end
      time += 1.hour
      index += 1
    end
    hourly_ranks_over_range
  end

  def self.daily_over_time_range(app_id, start_time, end_time)
    return {} unless app_id
    now = Time.zone.now
    time = start_time
    date = nil
    daily_ranks_over_range = {}
    size = ((end_time - start_time) / 1.day).ceil
    index = 0

    while time + 1.hour < end_time
      if date != time.strftime('%Y-%m')
        date = time.strftime('%Y-%m')
        ranks = S3Stats::Ranks.find_or_initialize_by_id("ranks/#{date}/#{app_id}")
      end

      if time + 38.hours > now
        hourly_ranks = S3Stats::Ranks.find_or_initialize_by_id("ranks/#{time.strftime("%Y-%m-%d")}/#{app_id}")
        ranks.populate_daily_from_hourly(hourly_ranks, time.day - 1)
      end

      ranks.all_ranks.each do |key, values|
        value = values[time.day - 1]
        unless value == 0
          daily_ranks_over_range[key] ||= Array.new(size, nil)
          daily_ranks_over_range[key][index] = value
        end
      end
      time += 1.day
      index += 1
    end
    daily_ranks_over_range
  end

  def strip_zero_arrays!(hash)
    hash.each do |key, value|
      hash.delete(key) if value.uniq == [0]
    end
  end
end
