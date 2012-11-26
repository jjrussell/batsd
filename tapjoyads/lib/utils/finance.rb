class Utils
  cattr_accessor :finance_data_bucket, :start_date, :end_date, :method_start_time

  # Utils.db_dump('2012-07-01', '2012-10-01')
  def self.db_dump(start_date_inclusive, end_date_exclusive)
    require 'csv'
    self.finance_data_bucket = S3.bucket(BucketNames::FINANCE_DATA)
    self.start_date          = start_date_inclusive
    self.end_date            = end_date_exclusive
    self.method_start_time   = Time.zone.now

    fetch_tables
    fetch_conversions
  end

  private

  def self.fetch_tables
    [
      {:klass => MonthlyAccounting, :full_dump => false, :fields => %w(id partner_id month year beginning_balance ending_balance website_orders invoiced_orders marketing_orders transfer_orders spend beginning_pending_earnings ending_pending_earnings payment_payouts transfer_payouts earnings created_at updated_at earnings_adjustments)},
      {:klass => Order,             :full_dump => false, :fields => %w(id partner_id payment_txn_id refund_txn_id coupon_id status payment_method amount created_at updated_at note invoice_id description note_to_client)},
      {:klass => Payout,            :full_dump => false, :fields => %w(id amount month year created_at updated_at partner_id status payment_method)},
      {:klass => EarningsAdjustment,:full_dump => false, :fields => %w(id amount created_at notes partner_id updated_at)},
      {:klass => Partner,           :full_dump => true,  :fields => %w(id name rev_share)},
      {:klass => App,               :full_dump => true,  :fields => %w(id partner_id name description price platform store_id store_url color created_at updated_at age_rating rotation_direction rotation_time hidden file_size_bytes supported_devices enabled_rating_offer_id secret_key released_at user_rating categories countries_blacklist)},
      {:klass => Currency,          :full_dump => true,  :fields => %w(id app_id name conversion_rate initial_balance  only_free_offers send_offer_data secret_key callback_url disabled_offers test_devices created_at updated_at max_age_rating disabled_partners partner_id ordinal spend_share minimum_featured_bid direct_pay_share offer_whitelist use_whitelist tapjoy_enabled hide_rewarded_app_installs currency_group_id rev_share_override minimum_offerwall_bid minimum_display_bid external_publisher udid_for_user_id reseller_id reseller_spend_share)},
      {:klass => Offer,             :full_dump => true,  :fields => %w(id partner_id item_id item_type name url price payment daily_budget overall_budget countries cities device_types pay_per_click allow_negative_balance user_enabled tapjoy_enabled created_at updated_at third_party_data conversion_rate show_rate self_promote_only age_rating featured min_conversion_rate next_stats_aggregation_time last_stats_aggregation_time last_daily_stats_aggregation_time stats_aggregation_interval publisher_app_whitelist name_suffix hidden payment_range_low payment_range_high bid reward_value multi_complete direct_pay low_balance min_bid_override next_daily_stats_aggregation_time active icon_id_override instructions rank_boost normal_conversion_rate normal_price normal_avg_revenue normal_bid over_threshold rewarded reseller_id cookie_tracking min_os_version screen_layout_sizes interval)},
    ].each{|table| fetch_table(table)}
  end

  # Conversions table is too large, do this in sql
  def self.fetch_conversions
    return if date_range_archived?

    Conversion.using_slave_db do
      final_end_date = Date.parse(end_date)
      current_start_date = Date.parse(start_date)
      while current_start_date < final_end_date
        next_start_date = [current_start_date + 4.days, final_end_date].min
        conversions_partial_dump(current_start_date.to_s, next_start_date.to_s)
        current_start_date = next_start_date
      end
      puts_with_time("[Conversion] Completed table data dump")
    end
  end

  def self.date_range_archived?
    earliest_conversion_time = Conversion.order('created_at').first.created_at
    if earliest_conversion_time > Time.zone.parse(start_date)
      # TODO implement grabbing archived conversions
      puts_with_time("[Conversions] *ABORT* data before #{earliest_conversion_time} have been archived.")
      true
    end
  end

  def self.conversions_partial_dump(start_date, end_date)
    base_filename = "conversion_#{start_date}"
    local_sql_file = "tmp/#{base_filename}.sql"

    s3_object = s3_object_for(base_filename, ".#{start_date}-#{end_date}", 'sql.gz')
    return if s3_object_exists?(s3_object)

    expected_count = Conversion.created_between(start_date, end_date).count
    return if expected_count_zero?(expected_count)

    conversion_local_dump(start_date, end_date, local_sql_file)
    return if counts_mismatch?(local_sql_file, expected_count)

    save_gzip_to_s3(local_sql_file, s3_object)
  ensure
    `rm #{local_sql_file} #{local_sql_file}.gz &> /dev/null`
  end

  def self.s3_object_exists?(s3_object)
    if s3_object.exists?
      puts_with_time("[Conversion] *SKIP* File #{s3_filename} exists.")
      true
    end
  end

  def self.expected_count_zero?(expected_count)
    if expected_count == 0
      puts_with_time("[Conversion] *SKIP* no conversion found")
      true
    end
  end

  def self.counts_mismatch?(local_sql_file, expected_count)
    backup_count = `wc -l #{local_sql_file}`.split[0].to_i - 1
    if backup_count != expected_count
      puts_with_time("[Conversion] *SKIP* expected #{expected_count} rows but backed up #{backup_count} rows")
      true
    end
  end

  def self.save_gzip_to_s3(local_sql_file, s3_object)
    `gzip -f #{local_sql_file}`
    puts_with_time("[Conversion] File compression complete")
    write_to_s3_with_retries(s3_object, :file => "#{local_sql_file}.gz")
  end

  def self.conversion_local_dump(start_date, end_date, local_sql_file)
    db_config = ActiveRecord::Base.configurations[Rails.env.production? ? 'production_slave_for_tapjoy_db' : Rails.env]
    execute = "SELECT * FROM conversions WHERE created_at >= '#{start_date}' AND created_at < '#{end_date}'"
    mysql_options = [
      "--user=#{db_config['username']}",
      "--password=#{db_config['password']}",
      "--host=#{db_config['host']}",
      "--execute=\"#{execute}\"",
    ].join(' ')
    `mysql #{mysql_options} #{db_config['database']} > #{local_sql_file}`

    puts_with_time("[Conversion] SQL dump complete")
  end

  def self.fetch_table(options)
    klass  = options[:klass]  or raise "missing option: klass"
    fields = options[:fields] or raise "missing option: fields"
    unless options[:full_dump]
      where = ["created_at >= ? and created_at < ?", start_date, end_date]
      object_suffix = ".#{start_date}-#{end_date}"
    end
    if klass == Offer
      ignore_fields = %w(publisher_app_whitelist instructions screen_layout_sizes)
    else
      ignore_fields = []
    end

    klass.using_slave_db do
      rows = klass.where(where)
      row_count = rows.count

      puts_with_time("[#{klass.name}] dumping #{row_count} rows")
      last_puts = Time.now

      data = [CSV.generate_line(fields)]
      rows.order(:created_at).find_each do |row|
        row_data = fields.map do |field|
          ignore_fields.include?(field) ? '' : row.try(field)
        end
        data << CSV.generate_line(row_data)
        if Time.now - last_puts > 60.seconds
          puts_with_time("[#{klass.name}] #{data.count * 100 / row_count}% complete (#{data.count} rows)")
          last_puts = Time.now
        end
      end

      s3_object = s3_object_for(klass.name.underscore, object_suffix)
      write_to_s3_with_retries(s3_object, data.join("\n"))
    end
  end

  def self.write_to_s3_with_retries(s3_object, options)
    retries = 3
    begin
      s3_object.write(options)
      puts_with_time("[S3] Saved #{s3_object.content_length} bytes to #{s3_object.public_url.to_s}")
    rescue AWS::Errors::Base => e
      if retries > 0
        puts_with_time("[S3] Encountered AWS Error; will try #{retries} more time(s)")
        retries -= 1
        sleep 5
        retry
      else
        puts_with_time("[S3] *ABORT* Unable to save to #{s3_object.public_url.to_s}")
      end
    end
  end


  def self.s3_object_for(name, suffix, extension='csv')
    finance_data_bucket.objects["data-dump/#{method_start_time.to_s(:yyyy_mm_dd)}/#{name}#{suffix}.#{extension}"]
  end

  def self.puts_with_time(msg)
    puts "#{(Time.now - method_start_time).to_i}s: #{msg}"
  end
end
