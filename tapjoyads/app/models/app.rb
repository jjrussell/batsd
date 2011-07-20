class App < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedRecord

  ALLOWED_PLATFORMS = { 'android' => 'Android', 'iphone' => 'iOS' }
  BETA_PLATFORMS    = { 'windows' => 'Windows Phone' }
  PLATFORMS         = ALLOWED_PLATFORMS.merge(BETA_PLATFORMS)
  PLATFORM_DETAILS = {
    'android' => {
      :expected_device_types => Offer::ANDROID_DEVICES,
      :sdk => {
        :connect  => ANDROID_CONNECT_SDK,
        :offers   => ANDROID_OFFERS_SDK,
        :vg       => ANDROID_VG_SDK,
      },
      :store_name => 'Market',
      :info_url => 'https://market.android.com/details?id=STORE_ID',
      :direct_store_url => 'market://search?q=STORE_ID',
      :default_actions_file_name => "TapjoyPPA.java",
      :min_action_offer_bid => 25,
      :versions => [ '1.5', '1.6', '2.0', '2.1', '2.2', '2.3', '3.0' ],
      :screen_layout_sizes => { 'small (320x426)' => '1', 'medium (320x470)' => '2', 'large (480x640)' => '3', 'extra large (720x960)' => '4' }
    },
    'iphone' => {
      :expected_device_types => Offer::APPLE_DEVICES,
      :sdk => {
        :connect  => IPHONE_CONNECT_SDK,
        :offers   => IPHONE_OFFERS_SDK,
        :vg       => IPHONE_VG_SDK,
      },
      :store_name => 'App Store',
      :info_url => 'http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=STORE_ID&mt=8',
      :direct_store_url => 'http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=STORE_ID&mt=8',
      :default_actions_file_name => "TJCPPA.h",
      :min_action_offer_bid => 35,
      :versions => [ '2.0', '2.1', '2.2', '3.0', '3.1', '3.2', '4.0', '4.1', '4.2', '4.3' ],
    },
    'windows' => {
      :expected_device_types => Offer::WINDOWS_DEVICES,
      :sdk => {
        :connect  => WINDOWS_CONNECT_SDK,
        :offers   => WINDOWS_OFFERS_SDK,
        :vg       => WINDOWS_VG_SDK,
      },
      :store_name => 'Marketplace',
      :info_url => 'http://social.zune.net/redirect?type=phoneapp&id=STORE_ID',
      :direct_store_url => 'http://social.zune.net/redirect?type=phoneapp&id=STORE_ID',
      :default_actions_file_name => '', #TODO fill this out
      :min_action_offer_bid => 25,
      :versions => [ '7.0' ],
    },
  }

  TRADEDOUBLER_COUNTRIES = Set.new(%w( GB FR DE IT IE ES NL AT CH BE DK FI NO SE LU PT GR ))
  MAXIMUM_INSTALLS_PER_PUBLISHER = 4000
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_app_id
  has_many :currencies, :order => 'ordinal ASC'
  has_one :primary_currency, :class_name => 'Currency', :conditions => 'id = app_id'
  has_one :rating_offer
  has_many :featured_offers, :class_name => 'Offer', :as => :item, :conditions => "featured = true"
  has_one :primary_featured_offer, :class_name => 'Offer', :as => :item, :conditions => "featured = true", :order => "created_at"
  has_many :action_offers
  has_many :non_rewarded_offers, :class_name => 'Offer', :as => :item, :conditions => "not rewarded"
  has_one :primary_non_rewarded_offer, :class_name => 'Offer', :as => :item, :conditions => "not rewarded", :order => "created_at"
  
  belongs_to :partner

  validates_presence_of :partner, :name, :secret_key
  validates_inclusion_of :platform, :in => PLATFORMS.keys

  before_validation_on_create :generate_secret_key
  
  after_create :create_primary_offer
  after_update :update_offers
  after_update :update_rating_offer
  
  named_scope :visible, :conditions => { :hidden => false }
  named_scope :by_platform, lambda { |platform| { :conditions => ["platform = ?", platform] } }

  delegate :conversion_rate, :to => :primary_currency, :prefix => true

  def is_ipad_only?
    supported_devices? && JSON.load(supported_devices).all?{ |i| i.match(/^ipad/i) }
  end

  def large_download?
    file_size_bytes.to_i > 20971520
  end

  def recently_released?
    released_at? && (Time.zone.now - released_at) < 7.day
  end

  def bad_rating?
    !user_rating.nil? && user_rating < 3.0
  end

  def platform_name
    PLATFORMS[platform]
  end
  
  def store_name
    PLATFORM_DETAILS[platform][:store_name]
  end

  def virtual_goods
    VirtualGood.select(:where => "app_id = '#{self.id}'")[:items]
  end
  
  def has_virtual_goods?
    VirtualGood.count(:where => "app_id = '#{self.id}'") > 0
  end

  def store_url
    if use_raw_url?
      read_attribute(:store_url)
    else
      direct_store_url
    end
  end
  
  def store_url=(url)
    if use_raw_url?
      write_attribute(:store_url, url)
    end
  end

  def categories=(arr)
    write_attribute(:categories, arr.join(';'))
  end

  def categories
    (read_attribute(:categories)||'').split(';')
  end

  def primary_category
    categories.first.humanize if categories.present?
  end

  def info_url
    PLATFORM_DETAILS[platform][:info_url].sub('STORE_ID', store_id.to_s)
  end

  def direct_store_url
    PLATFORM_DETAILS[platform][:direct_store_url].sub('STORE_ID', store_id.to_s)
  end

  def primary_country
    countries = primary_offer.present? && self.primary_offer.countries
    if countries.present? && !JSON.parse(countries).include?("US")
      JSON.parse(countries).first
    else
      "us"
    end
  end

  ##
  # Grab data from the app store and mutate self with data.
  def fill_app_store_data(country=nil)
    return {} if store_id.blank?
    data = AppStore.fetch_app_by_id(store_id, platform, country)
    if (data.nil?) # might not be available in the US market
      data = AppStore.fetch_app_by_id(store_id, platform, primary_country)
    end
    raise "Fetching app store data failed for app: #{name} (#{id})." if data.nil?
    self.name               = data[:title]
    self.price              = (data[:price].to_f * 100).round
    self.description        = data[:description]
    self.age_rating         = data[:age_rating]
    self.file_size_bytes    = data[:file_size_bytes]
    self.released_at        = data[:released_at]
    self.user_rating        = data[:user_rating]
    self.categories         = data[:categories]
    self.supported_devices  = data[:supported_devices].present? ? data[:supported_devices].to_json : nil
    
    # TODO: Real multi-currency handling. For now simply set the price to a positive value if it's not USD.
    if data[:currency].present? && data[:currency] != 'USD' && price > 0
      self.price = 99
    end
    
    download_icon(data[:icon_url], data[:small_icon_url]) unless new_record?
    data
  end

  def download_icon(url, small_url)
    return if url.blank?
    
    begin
      icon_src_blob = Downloader.get(url, :timeout => 30)
      small_icon_src_blob = small_url.nil? ? icon_src_blob : Downloader.get(small_url, :timeout => 30)
    rescue Exception => e
      Rails.logger.info "Failed to download icon for url: #{url}. Error: #{e}"
      Notifier.alert_new_relic(AppDataFetchError, "icon url #{url} for app id #{id}. Error: #{e}")
    else
      primary_offer.save_icon!(icon_src_blob, small_icon_src_blob)
    end
  end

  def get_icon_url(options = {})
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(id)}.merge(options))
  end

  def get_offer_list(options = {})
    device               = options.delete(:device)               { |k| raise "#{k} is a required argument" }
    currency             = options.delete(:currency)             { |k| raise "#{k} is a required argument" }
    geoip_data           = options.delete(:geoip_data)           { {} }
    required_length      = options.delete(:required_length)      { 999 }
    include_rating_offer = options.delete(:include_rating_offer) { false }
    direct_pay_providers = options.delete(:direct_pay_providers) { [] }
    app_version          = options.delete(:app_version)
    device_type          = options.delete(:device_type)
    type                 = options.delete(:type)
    source               = options.delete(:source)
    exp                  = options.delete(:exp)
    os_version           = options.delete(:os_version)
    library_version      = options.delete(:library_version) || ''
    screen_layout_size   = options.delete(:screen_layout_size)

    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    return [ [], 0 ] if type == Offer::CLASSIC_OFFER_TYPE || !currency.tapjoy_enabled?
    
    final_offer_list  = []
    num_rejected      = 0
    offer_list_length = 0
    hide_app_offers   = currency.hide_rewarded_app_installs_for_version?(app_version, source)
    
    if include_rating_offer && enabled_rating_offer_id.present?
      rate_app_offer = Offer.find_in_cache(enabled_rating_offer_id)
      if rate_app_offer.present? && rate_app_offer.accepting_clicks?
        offer_list_length += 1
        if rate_app_offer.should_reject?(self, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_app_offers, library_version, os_version, screen_layout_size)
          num_rejected += 1
        else
          final_offer_list << rate_app_offer
        end
      end
    end
    
    offer_list_length += currency.get_cached_offers({ :type => type, :exp => exp }) do |offers|
      offers.each do |offer|
        if offer.should_reject?(self, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_app_offers, library_version, os_version, screen_layout_size)
          num_rejected += 1
        else
          final_offer_list << offer
        end
        break if required_length == final_offer_list.length
      end
      
      'break' if required_length == final_offer_list.length
    end
    
    [ final_offer_list, offer_list_length - final_offer_list.length - num_rejected ]
  end
  
  def display_money_share
    0.6
  end

  def can_have_new_currency?
    currencies.empty? || !currencies.any? { |c| Currency::SPECIAL_CALLBACK_URLS.include?(c.callback_url) }
  end

  def default_actions_file_name
    PLATFORM_DETAILS[platform][:default_actions_file_name]
  end

  def generate_actions_file
    case platform
    when 'android'
      file_output =  "package com.tapjoy;\n"
      file_output += "\n"
      file_output += "public class TapjoyPPA\n"
      file_output += "{\n"
      action_offers.each do |action_offer|
        file_output += "  public static final String #{action_offer.variable_name} = \"#{action_offer.id}\"; // #{action_offer.name}\n"
      end
      file_output += "}"
    when 'iphone'
      file_output =  ""
      action_offers.each do |action_offer|
        file_output += "#define #{action_offer.variable_name} @\"#{action_offer.id}\" // #{action_offer.name}\n"
      end
    when 'windows'
      #TODO fill this out
      file_output = "// Not available yet\n"
    end
    file_output
  end
  
  def offers_with_last_run_time
    [ primary_offer ] + action_offers.collect(&:primary_offer).sort { |a, b| a.name <=> b.name }
  end

  def get_offer_device_types
    is_ipad_only? ? Offer::IPAD_DEVICES : PLATFORM_DETAILS[platform][:expected_device_types]
  end

  def sdk_url(type)
    PLATFORM_DETAILS[platform][:sdk][type]
  end
  
  def os_versions
    PLATFORM_DETAILS[platform][:versions]
  end
  
  def screen_layout_sizes
    PLATFORM_DETAILS[platform][:screen_layout_sizes].nil? ? [] : PLATFORM_DETAILS[platform][:screen_layout_sizes].sort{ |a,b| a[1] <=> b[1] }
  end

private
  
  def generate_secret_key
    return if secret_key.present?
    
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890'
    new_secret_key = ''
    20.times do
      new_secret_key << alphabet[rand(alphabet.size)]
    end
    self.secret_key = new_secret_key
  end
  
  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.price = price
    offer.bid = offer.min_bid
    offer.url = store_url
    offer.device_types = get_offer_device_types.to_json
    offer.third_party_data = store_id
    offer.age_rating = age_rating
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed? && name_was == offer.name
      if price_changed?
        offer.price = price
        offer.bid = offer.min_bid if offer.bid < offer.min_bid
      end
      offer.url = store_url if store_url_changed? || use_raw_url_changed? || store_id_changed?
      offer.third_party_data = store_id if store_id_changed?
      offer.age_rating = age_rating if age_rating_changed?
      offer.hidden = hidden if hidden_changed?
      offer.tapjoy_enabled = false if hidden? && hidden_changed?
      offer.device_types = get_offer_device_types.to_json if store_id_changed?
      offer.save! if offer.changed?
    end
  end

  def update_rating_offer
    if (name_changed? || store_id_changed?) && rating_offer.present?
      rating_offer.save!
    end
  end
end
