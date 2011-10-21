class Conversion < ActiveRecord::Base
  include UuidPrimaryKey

  REWARD_TYPES = {
    # Base types
    'offer'                       => 0,
    'install'                     => 1,
    'rating'                      => 2,
    'generic'                     => 3,
    'install_jailbroken'          => 4,
    'action'                      => 5,
    'video'                       => 6,

    # Special
    'imported'                    => 999,

    # Display types, (all base types +1000)
    'display_offer'               => 1000,
    'display_install'             => 1001,
    'display_rating'              => 1002,
    'display_generic'             => 1003,
    'display_install_jailbroken'  => 1004,
    'display_action'              => 1005,
    'display_video'               => 1006,

    # Featured types (all base types +2000)
    'featured_offer'              => 2000,
    'featured_install'            => 2001,
    'featured_rating'             => 2002,
    'featured_generic'            => 2003,
    'featured_install_jailbroken' => 2004,
    'featured_action'             => 2005,
    'featured_video'              => 2006,
  }

  STAT_TO_REWARD_TYPE_MAP = {
    'offers'                    => { :reward_types => [ 0, 2, 3, 5, 6 ],                                        :attr_name => 'publisher_app_id' },
    'published_installs'        => { :reward_types => [ 1, 4 ],                                                 :attr_name => 'publisher_app_id' },
    'display_conversions'       => { :reward_types => [ 1000, 1001, 1002, 1003, 1004, 1005, 1006 ],             :attr_name => 'publisher_app_id' },
    'featured_published_offers' => { :reward_types => [ 2000, 2001, 2002, 2003, 2004, 2005, 2006 ],             :attr_name => 'publisher_app_id' },
    'paid_installs'             => { :reward_types => [ 0, 1, 2, 3, 5, 6, 2000, 2001, 2002, 2003, 2005, 2006 ], :attr_name => 'advertiser_offer_id' },
    'jailbroken_installs'       => { :reward_types => [ 4, 2004 ],                                              :attr_name => 'advertiser_offer_id' },
    'offers_revenue'            => { :reward_types => [ 0, 2, 3, 5, 6 ],                                        :attr_name => 'publisher_app_id',    :sum_attr => :publisher_amount },
    'installs_revenue'          => { :reward_types => [ 1, 4 ],                                                 :attr_name => 'publisher_app_id',    :sum_attr => :publisher_amount },
    'display_revenue'           => { :reward_types => [ 1000, 1001, 1002, 1003, 1004, 1005, 1006 ],             :attr_name => 'publisher_app_id',    :sum_attr => :publisher_amount },
    'featured_revenue'          => { :reward_types => [ 2000, 2001, 2002, 2003, 2004, 2005, 2006 ],             :attr_name => 'publisher_app_id',    :sum_attr => :publisher_amount },
    'installs_spend'            => { :reward_types => [ 0, 1, 2, 3, 5, 6, 2000, 2001, 2002, 2003, 2005, 2006 ], :attr_name => 'advertiser_offer_id', :sum_attr => :advertiser_amount },
  }

  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :advertiser_offer, :class_name => 'Offer'

  validates_presence_of :publisher_app
  validates_presence_of :advertiser_offer, :unless => Proc.new { |conversion| conversion.advertiser_offer_id.blank? }
  validates_numericality_of :advertiser_amount, :publisher_amount, :tapjoy_amount, :only_integer => true, :allow_nil => false
  validates_inclusion_of :reward_type, :in => REWARD_TYPES.values

  before_save :sanitize_reward_id
  after_create :update_partner_amounts

  named_scope :created_since, lambda { |date| { :conditions => [ "created_at >= ?", date ] } }
  named_scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }

  named_scope :non_display, :conditions => ["reward_type < 1000 OR reward_type >= 2000"]
  named_scope :exclude_pub_apps, lambda { |apps| { :conditions => ["publisher_app_id NOT IN (?)", apps] } }
  named_scope :include_pub_apps, lambda { |apps| { :conditions => ["publisher_app_id IN (?)", apps] } }

  def self.get_stat_definitions(reward_type)
    case reward_type
    when 0, 2, 3, 5, 6
      [ { :stat => 'offers',         :attr => :publisher_app_id },
        { :stat => 'paid_installs',  :attr => :advertiser_offer_id },
        { :stat => 'offers_revenue', :attr => :publisher_app_id,    :increment => :publisher_amount },
        { :stat => 'installs_spend', :attr => :advertiser_offer_id, :increment => :advertiser_amount } ]
    when 1
      [ { :stat => 'published_installs', :attr => :publisher_app_id },
        { :stat => 'paid_installs',      :attr => :advertiser_offer_id },
        { :stat => 'installs_revenue',   :attr => :publisher_app_id,    :increment => :publisher_amount },
        { :stat => 'installs_spend',     :attr => :advertiser_offer_id, :increment => :advertiser_amount } ]
    when 4
      [ { :stat => 'jailbroken_installs', :attr => :advertiser_offer_id },
        { :stat => 'published_installs',  :attr => :publisher_app_id },
        { :stat => 'installs_revenue',    :attr => :publisher_app_id, :increment => :publisher_amount } ]
    when 1000, 1001, 1002, 1003, 1004, 1005, 1006
      [ { :stat => 'display_conversions', :attr => :publisher_app_id },
        { :stat => 'display_revenue',     :attr => :publisher_app_id, :increment => :publisher_amount } ]
    when 2000, 2001, 2002, 2003, 2005, 2006
      [ { :stat => 'featured_published_offers', :attr => :publisher_app_id },
        { :stat => 'paid_installs',             :attr => :advertiser_offer_id },
        { :stat => 'featured_revenue',          :attr => :publisher_app_id,    :increment => :publisher_amount },
        { :stat => 'installs_spend',            :attr => :advertiser_offer_id, :increment => :advertiser_amount } ]
    when 2004
      [ { :stat => 'jailbroken_installs',       :attr => :advertiser_offer_id },
        { :stat => 'featured_published_offers', :attr => :publisher_app_id },
        { :stat => 'featured_revenue',          :attr => :publisher_app_id, :increment => :publisher_amount } ]
    else
      []
    end
  end

  def self.archive_cutoff_time
    Time.zone.now.beginning_of_month - 3.months
  end

  def self.accounting_cutoff_time
    Time.zone.now.beginning_of_month.prev_month
  end

  def self.is_partitioned?
    Conversion.connection.select_one("SHOW TABLE STATUS WHERE Name = '#{table_name}'")['Create_options'] == 'partitioned'
  end

  def self.get_partitions
    partitions = []
    if is_partitioned?
      db_name = ActiveRecord::Base.configurations[Rails.env]['database']
      partitions = Conversion.connection.select_all("SELECT * FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = '#{db_name}' AND TABLE_NAME = '#{table_name}' ORDER BY PARTITION_ORDINAL_POSITION ASC")
      partitions.each do |partition|
        partition['CUTOFF_TIME'] = Time.zone.parse(Conversion.connection.select_value("SELECT FROM_DAYS(#{partition['PARTITION_DESCRIPTION']})"))
      end
    end
    partitions
  end

  def self.add_partition(cutoff_time)
    if is_partitioned?
      num_days = Conversion.connection.select_value("SELECT TO_DAYS('#{cutoff_time.to_s(:db)}')")
      Conversion.connection.execute("ALTER TABLE #{quoted_table_name} ADD PARTITION (PARTITION p#{num_days} VALUES LESS THAN (#{num_days}) COMMENT 'created_at < #{cutoff_time.to_s(:db)}')")
    end
  end

  def self.drop_archived_partitions
    get_partitions.each do |partition|
      next unless partition['CUTOFF_TIME'] <= archive_cutoff_time
      Conversion.connection.execute("ALTER TABLE #{quoted_table_name} DROP PARTITION #{partition['PARTITION_NAME']}")
    end
  end

  def self.restore_from_file(filename, concurrency = 4000)
    Benchmark.realtime do
      f = File.open(filename, 'r')
      count = 0
      columns = "(#{f.readline.gsub("\n", '').gsub("\t", ', ')})"
      values = []
      f.each_line do |line|
        values << "('#{line.gsub("\n", '').gsub("\t", "', '")}')"
        if values.size == concurrency || f.eof?
          Conversion.connection.execute("INSERT INTO #{quoted_table_name} #{columns} VALUES #{values.join(', ')}")
          count += values.size
          sleep(0.05)
          values = []
          puts "#{Time.zone.now.to_s(:db)} - restored: #{count}" if count % 10000 == 0 || f.eof?
        end
      end
      f.close
    end
  end

  def reward_type_string=(string)
    type = REWARD_TYPES[string]
    raise "Unknown reward type: #{string}" if type.nil?
    self.reward_type = type
  end

  def reward_type_string_for_displayer=(string)
    self.reward_type_string = "display_#{string}"
  end

  def update_realtime_stats
    Conversion.get_stat_definitions(reward_type).each do |stat_definition|
      stat_name  = stat_definition[:stat]
      attr_value = send(stat_definition[:attr])
      count_inc  = stat_definition[:increment].present? ? send(stat_definition[:increment]) : 1

      if attr_value.present?
        mc_key = Stats.get_memcache_count_key(stat_name, attr_value, created_at)
        Mc.increment_count(mc_key, false, 1.day, count_inc)

        if stat_name == 'paid_installs' || stat_name == 'installs_spend'
          stat_path = [ 'countries', (Stats::COUNTRY_CODES[country].present? ? "#{stat_name}.#{country}" : "#{stat_name}.other") ]
          mc_key = Stats.get_memcache_count_key(stat_path, attr_value, created_at)
          Mc.increment_count(mc_key, false, 1.day, count_inc)
        end
      end
    end
  end

private

  def update_partner_amounts
    partners = []
    partners << publisher_app.partner_id unless publisher_amount == 0
    partners << advertiser_offer.partner_id unless advertiser_amount == 0 || advertiser_offer.nil?

    return true if partners.empty?

    Partner.find_all_by_id(partners, :lock => "FOR UPDATE")
    Partner.connection.execute("UPDATE #{Partner.quoted_table_name} SET pending_earnings = (pending_earnings + #{publisher_amount}) WHERE id = '#{publisher_app.partner_id}'") unless publisher_amount == 0
    Partner.connection.execute("UPDATE #{Partner.quoted_table_name} SET balance = (balance + #{advertiser_amount}) WHERE id = '#{advertiser_offer.partner_id}'") unless advertiser_amount == 0 || advertiser_offer.nil?
  end

  def sanitize_reward_id
    self.reward_id = nil unless reward_id =~ UUID_REGEX
  end

end
