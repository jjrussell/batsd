class RiskProfile < SimpledbShardedResource
  self.num_domains = NUM_RISK_PROFILE_DOMAINS

  ENTITY_TO_CATEGORY_MAP = {
    'OFFER'      => { :category => 'SYSTEM',     :weight => 2 },
    'ADVERTISER' => { :category => 'SYSTEM',     :weight => 1 },
    'APP'        => { :category => 'SYSTEM',     :weight => 2 },
    'PUBLISHER'  => { :category => 'SYSTEM',     :weight => 1 },
    'COUNTRY'    => { :category => 'SYSTEM',     :weight => 1 },
    'USER'       => { :category => 'INDIVIDUAL', :weight => 2 },
    'DEVICE'     => { :category => 'INDIVIDUAL', :weight => 2 },
    'IPADDR'     => { :category => 'INDIVIDUAL', :weight => 1 },
  }

  MINIMUM_TOTAL_OFFSET = -100
  MAXIMUM_TOTAL_OFFSET = 100
  VELOCITY_WINDOW_HOURS = 72
  NO_HISTORY_OFFSET = 0

  self.sdb_attr :category
  self.sdb_attr :weight
  self.sdb_attr :curated_offsets, :type => :json, :default_value => {}
  self.sdb_attr :historical_offsets, :type => :json, :default_value => {}
  self.sdb_attr :conversion_tracker, :type => :json, :default_value => {}
  self.sdb_attr :block_tracker, :type => :json, :default_value => {}
  self.sdb_attr :revenue_tracker, :type => :json, :default_value => {}

  def after_initialize
    type = @key.split('.').first
    raise 'Unknown entity type' unless ENTITY_TO_CATEGORY_MAP.keys.include?(type)

    self.category = ENTITY_TO_CATEGORY_MAP[type][:category]
    self.weight = ENTITY_TO_CATEGORY_MAP[type][:weight]
  end

  def add_curated_offset(name, value)
    parsed_curated_offsets = curated_offsets
    parsed_curated_offsets[name] = { :offset => value, :updated => Time.now.to_f }
    self.curated_offsets = parsed_curated_offsets
    save
  end

  def add_historical_offset(name, value)
    parsed_historical_offsets = historical_offsets
    parsed_historical_offsets[name] =  { :offset => value, :updated => Time.now.to_f }
    self.historical_offsets = parsed_historical_offsets
    save
  end

  def total_score_offset
    parsed_curated_offsets = curated_offsets
    parsed_historical_offsets = historical_offsets

    puts "curated: #{parsed_curated_offsets.inspect}"
    puts "historical: #{parsed_historical_offsets.inspect}"

    total = 0
    total += parsed_curated_offsets.values.inject(0) { |sum, h| puts "offset: #{h['offset']}"; sum += h['offset'] } unless parsed_curated_offsets.empty?
    if parsed_historical_offsets.empty?
      total += NO_HISTORY_OFFSET
    else
      total += parsed_historical_offsets.values.inject(0) { |sum, h| sum += h['offset'] }
    end

    return MINIMUM_TOTAL_OFFSET if total < MINIMUM_TOTAL_OFFSET
    return MAXIMUM_TOTAL_OFFSET if total > MAXIMUM_TOTAL_OFFSET

    total
  end

  def process_conversion(reward)
    clear_expired_values

    hour = Time.now.change(:min => 0).to_f.to_s
    if @parsed_conversion_tracker[hour]
      @parsed_conversion_tracker[hour] += 1
      @parsed_revenue_tracker[hour] -= reward.advertiser_amount
    else
      @parsed_conversion_tracker[hour] = 1
      @parsed_revenue_tracker[hour] = -reward.advertiser_amount
    end

    self.conversion_tracker = @parsed_conversion_tracker
    self.revenue_tracker = @parsed_revenue_tracker
    save
  end

  def process_block
    clear_expired_values

    hour = Time.now.change(:min => 0).to_f.to_s
    if @parsed_block_tracker[hour]
      @parsed_block_tracker[hour] += 1
    else
      @parsed_block_tracker[hour] = 1
    end

    self.block_tracker = @parsed_block_tracker
    save
  end

  def conversion_count(window)
    start = (Time.now - window.hours).change(:min => 0).to_f.to_s
    @parsed_conversion_tracker = conversion_tracker
    @parsed_conversion_tracker.inject(0) { |count, pair| pair[0] >= start ? count+pair[1] : count }
  end

  def revenue_total(window)
    start = (Time.now - window.hours).change(:min => 0).to_f.to_s
    @parsed_revenue_tracker = revenue_tracker
    @parsed_revenue_tracker.inject(0) { |sum, pair| pair[0] >= start ? sum+pair[1] : sum }
  end

  def block_count(window)
    start = (Time.now - window.hours).change(:min => 0).to_f.to_s
    @parsed_block_tracker = block_tracker
    @parsed_block_tracker.inject(0) { |sum, pair| pair[0] >= start ? sum+pair[1] : sum }
  end

  def block_percent(window)
    blocks = block_count(window)
    conversions = conversion_count(window)
    return 0.0 if (blocks + conversions) == 0
    blocks.to_f / (blocks + conversions) * 100
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_RISK_PROFILE_DOMAINS

    "risk_profiles_#{domain_number}"
  end

  private

  def clear_expired_values
    @parsed_conversion_tracker = conversion_tracker
    @parsed_block_tracker = block_tracker
    @parsed_revenue_tracker = revenue_tracker

    start = (Time.now - VELOCITY_WINDOW_HOURS.hours).change(:min => 0).to_f.to_s
    @parsed_conversion_tracker.delete_if { |key, value| key < start }
    @parsed_block_tracker.delete_if { |key, value| key < start }
    @parsed_revenue_tracker.delete_if { |key, value| key < start }
  end
end
