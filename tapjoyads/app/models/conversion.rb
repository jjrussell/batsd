# == Schema Information
#
# Table name: conversions
#
#  id                     :string(36)      not null, primary key
#  reward_id              :string(36)
#  advertiser_offer_id    :string(36)
#  publisher_app_id       :string(36)      not null
#  advertiser_amount      :integer(4)      not null
#  publisher_amount       :integer(4)      not null
#  tapjoy_amount          :integer(4)      not null
#  reward_type            :integer(4)      not null
#  created_at             :datetime
#  updated_at             :datetime
#  country                :string(2)
#  publisher_partner_id   :string(36)      not null
#  advertiser_partner_id  :string(36)      not null
#  publisher_reseller_id  :string(36)
#  advertiser_reseller_id :string(36)
#  spend_share            :float
#

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
    'reengagement'                => 7,
    'deeplink'                    => 8,
    'survey'                      => 9,
    'coupon'                      => 10,

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
    'display_reengagement'        => 1007,
    'display_deeplink'            => 1008,
    'display_survey'              => 1009,
    'display_coupon'              => 1010,

    # Featured types (all base types +2000)
    'featured_offer'              => 2000,
    'featured_install'            => 2001,
    'featured_rating'             => 2002,
    'featured_generic'            => 2003,
    'featured_install_jailbroken' => 2004,
    'featured_action'             => 2005,
    'featured_video'              => 2006,
    'featured_reengagement'       => 2007,
    'featured_deeplink'           => 2008,
    'featured_survey'             => 2009,
    'featured_coupon'             => 2010,

    # TJM types (all base types +3000)
    'tjm_offer'                   => 3000,
    'tjm_install'                 => 3001,
    'tjm_rating'                  => 3002,
    'tjm_generic'                 => 3003,
    'tjm_install_jailbroken'      => 3004,
    'tjm_action'                  => 3005,
    'tjm_video'                   => 3006,
    'tjm_reengagement'            => 3007,
    'tjm_deeplink'                => 3008,
    'tjm_survey'                  => 3009,
    'tjm_coupon'                  => 3010,
  }

  STAT_TO_REWARD_TYPE_MAP = {
    'offers'                    => { :reward_types => [ 0, 2, 3, 5, 6, 9 ],                               :attr_name => 'publisher_app_id',   :segment_by_store => true },
    'published_installs'        => { :reward_types => [ 1, 4 ],                                           :attr_name => 'publisher_app_id',   :segment_by_store => true },
    'display_conversions'       => { :reward_types => [ 1000, 1001, 1002, 1003, 1004, 1005, 1006, 1009 ], :attr_name => 'publisher_app_id',   :segment_by_store => true },
    'featured_published_offers' => { :reward_types => [ 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2009 ], :attr_name => 'publisher_app_id',   :segment_by_store => true },
    'paid_installs'             => { :reward_types => [ 0, 1, 2, 3, 5, 6, 8, 9, 2000, 2001, 2002, 2003, 2005, 2006, 2009, 3000, 3001, 3002, 3003, 3005, 3006, 3009 ], :attr_name => 'advertiser_offer_id', :segment_by_store => false },
    'jailbroken_installs'       => { :reward_types => [ 4, 2004, 3004 ],                                  :attr_name => 'advertiser_offer_id', :segment_by_store => false },
    'offers_revenue'            => { :reward_types => [ 0, 2, 3, 5, 6, 9 ],                               :attr_name => 'publisher_app_id',   :segment_by_store => true, :sum_attr => :publisher_amount },
    'installs_revenue'          => { :reward_types => [ 1, 4 ],                                           :attr_name => 'publisher_app_id',   :segment_by_store => true, :sum_attr => :publisher_amount },
    'display_revenue'           => { :reward_types => [ 1000, 1001, 1002, 1003, 1004, 1005, 1006, 1009 ], :attr_name => 'publisher_app_id',   :segment_by_store => true, :sum_attr => :publisher_amount },
    'featured_revenue'          => { :reward_types => [ 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2009 ], :attr_name => 'publisher_app_id',   :segment_by_store => true, :sum_attr => :publisher_amount },
    'installs_spend'            => { :reward_types => [ 0, 1, 2, 3, 5, 6, 9, 2000, 2001, 2002, 2003, 2005, 2006, 2009, 3000, 3001, 3002, 3003, 3005, 3006, 3009 ], :attr_name => 'advertiser_offer_id', :segment_by_store => false, :sum_attr => :advertiser_amount },
    'tjm_offers'                => { :reward_types => [ 3000, 3002, 3003, 3005, 3006, 3009 ],             :attr_name => 'publisher_app_id',   :segment_by_store => true },
    'tjm_published_installs'    => { :reward_types => [ 3001, 3004 ],                                     :attr_name => 'publisher_app_id',   :segment_by_store => true },
    'tjm_offers_revenue'        => { :reward_types => [ 3000, 3002, 3003, 3005, 3006, 3009 ],             :attr_name => 'publisher_app_id',   :segment_by_store => true, :sum_attr => :publisher_amount },
    'tjm_installs_revenue'      => { :reward_types => [ 3001, 3004 ],                                     :attr_name => 'publisher_app_id',   :segment_by_store => true, :sum_attr => :publisher_amount },
  }

  attr_accessor :store_name

  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :advertiser_offer, :class_name => 'Offer'
  belongs_to :publisher_partner, :class_name => 'Partner'
  belongs_to :advertiser_partner, :class_name => 'Partner'

  validates_presence_of :publisher_app, :advertiser_offer, :publisher_partner, :advertiser_partner
  validates_numericality_of :advertiser_amount, :publisher_amount, :tapjoy_amount, :only_integer => true, :allow_nil => false
  validates_inclusion_of :reward_type, :in => REWARD_TYPES.values

  after_create :update_partner_amounts

  scope :created_since, lambda { |date| { :conditions => [ "created_at >= ?", date ] } }
  scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }

  def self.get_stat_definitions(reward_type)
    case reward_type
    when 0, 2, 3, 5, 6, 9
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
    when 8
      [ { :stat => 'paid_installs',  :attr => :advertiser_offer_id } ]
    when 1000, 1001, 1002, 1003, 1004, 1005, 1006, 1009
      [ { :stat => 'display_conversions', :attr => :publisher_app_id },
        { :stat => 'display_revenue',     :attr => :publisher_app_id, :increment => :publisher_amount } ]
    when 2000, 2001, 2002, 2003, 2005, 2006, 2009
      [ { :stat => 'featured_published_offers', :attr => :publisher_app_id },
        { :stat => 'paid_installs',             :attr => :advertiser_offer_id },
        { :stat => 'featured_revenue',          :attr => :publisher_app_id,    :increment => :publisher_amount },
        { :stat => 'installs_spend',            :attr => :advertiser_offer_id, :increment => :advertiser_amount } ]
    when 2004
      [ { :stat => 'jailbroken_installs',       :attr => :advertiser_offer_id },
        { :stat => 'featured_published_offers', :attr => :publisher_app_id },
        { :stat => 'featured_revenue',          :attr => :publisher_app_id, :increment => :publisher_amount } ]
    when 3000, 3002, 3003, 3005, 3006, 3009
      [ { :stat => 'tjm_offers',         :attr => :publisher_app_id },
        { :stat => 'paid_installs',      :attr => :advertiser_offer_id },
        { :stat => 'tjm_offers_revenue', :attr => :publisher_app_id,    :increment => :publisher_amount },
        { :stat => 'installs_spend',     :attr => :advertiser_offer_id, :increment => :advertiser_amount } ]
    when 3001
      [ { :stat => 'tjm_published_installs', :attr => :publisher_app_id },
        { :stat => 'paid_installs',          :attr => :advertiser_offer_id },
        { :stat => 'tjm_installs_revenue',   :attr => :publisher_app_id,    :increment => :publisher_amount },
        { :stat => 'installs_spend',         :attr => :advertiser_offer_id, :increment => :advertiser_amount } ]
    when 3004
      [ { :stat => 'jailbroken_installs',    :attr => :advertiser_offer_id },
        { :stat => 'tjm_published_installs', :attr => :publisher_app_id },
        { :stat => 'tjm_installs_revenue',   :attr => :publisher_app_id, :increment => :publisher_amount } ]
    else
      []
    end
  end

  def self.backup_cutoff_time
    Time.zone.now.beginning_of_month
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
      increment_running_counts(stat_name, attr_value, created_at, count_inc) if attr_value.present?
    end
  end

  private

  def update_partner_amounts
    partners = []
    partners << publisher_partner_id unless publisher_amount == 0
    partners << advertiser_partner_id unless advertiser_amount == 0

    return true if partners.empty?

    Partner.find_all_by_id(partners, :lock => "FOR UPDATE")
    Partner.connection.execute("UPDATE #{Partner.quoted_table_name} SET pending_earnings = (pending_earnings + #{publisher_amount}) WHERE id = '#{publisher_partner_id}'") unless publisher_amount == 0
    Partner.connection.execute("UPDATE #{Partner.quoted_table_name} SET balance = (balance + #{advertiser_amount}) WHERE id = '#{advertiser_partner_id}'") unless advertiser_amount == 0
  end

  def increment_running_counts(stat_name, attr_value, time, count_inc)
    keys = [ Stats.get_memcache_count_key(stat_name, attr_value, time) ]

    if stat_name == 'paid_installs' || stat_name == 'installs_spend'
      stat_path = [ 'countries', (Stats::COUNTRY_CODES[country].present? ? "#{stat_name}.#{country}" : "#{stat_name}.other") ]
      keys << Stats.get_memcache_count_key(stat_path, attr_value, time)
    end
    segment_stat = Stats.get_segment_stat(stat_name, store_name)
    keys << Stats.get_memcache_count_key(segment_stat, attr_value, time) if segment_stat

    keys.each do |mc_key|
      StatsCache.increment_count(mc_key, false, 1.day, count_inc)
    end
  end
end
