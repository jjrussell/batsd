class App < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  json_set_field :countries_blacklist

  ALLOWED_PLATFORMS = { 'android' => 'Android', 'iphone' => 'iOS' }
  BETA_PLATFORMS    = { 'windows' => 'Windows Phone' }
  PLATFORMS         = ALLOWED_PLATFORMS.merge(BETA_PLATFORMS)
  APPSTORE_COUNTRIES_OPTIONS = GeoIP::CountryName.zip(GeoIP::CountryCode).select do |name, code|
      code.match(/[a-z]{2}/i)
    end.map do |name, code|
      ["#{code} -- #{name}", code]
    end.sort.unshift(["Select a country", ""])
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
      :store_url => 'market://search?q=STORE_ID',
      :default_actions_file_name => "TapjoyPPA.java",
      :min_action_offer_bid => 25,
      :versions => [ '1.5', '1.6', '2.0', '2.1', '2.2', '2.3', '3.0' ],
      :cell_download_limit_bytes => 99.gigabyte,
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
      :store_url => 'http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=STORE_ID&mt=8',
      :default_actions_file_name => "TJCPPA.h",
      :min_action_offer_bid => 35,
      :versions => [ '2.0', '2.1', '2.2', '3.0', '3.1', '3.2', '4.0', '4.1', '4.2', '4.3', '5.0' ],
      :cell_download_limit_bytes => 20.megabytes
    },
    'windows' => {
      :expected_device_types => Offer::WINDOWS_DEVICES,
      :sdk => {
        :connect  => WINDOWS_CONNECT_SDK,
        :offers   => WINDOWS_OFFERS_SDK,
        :vg       => WINDOWS_OFFERS_SDK,
      },
      :store_name => 'Marketplace',
      :info_url => 'http://social.zune.net/redirect?type=phoneapp&id=STORE_ID',
      :store_url => 'http://social.zune.net/redirect?type=phoneapp&id=STORE_ID',
      :default_actions_file_name => '', #TODO fill this out
      :min_action_offer_bid => 25,
      :versions => [ '7.0' ],
      :cell_download_limit_bytes => 20.megabytes
    },
  }

  TRADEDOUBLER_COUNTRIES = Set.new(%w( GB FR DE IT IE ES NL AT CH BE DK FI NO SE LU PT GR ))
  MAXIMUM_INSTALLS_PER_PUBLISHER = 4000
  PREVIEW_PUBLISHER_APP_ID = "bba49f11-b87f-4c0f-9632-21aa810dd6f1" # EasyAppPublisher... used for "ad preview" generation

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
  has_many :app_metadata_mappings
  has_many :app_metadatas, :through => :app_metadata_mappings
  has_one :primary_app_metadata, :through => :app_metadata_mappings, :source => :app_metadata, :order => "created_at"
  has_many :app_reviews

  belongs_to :partner

  validates_presence_of :partner, :name, :secret_key
  validates_inclusion_of :platform, :in => PLATFORMS.keys

  before_validation_on_create :generate_secret_key

  after_create :create_primary_offer
  after_update :update_offers
  after_update :update_currencies

  named_scope :visible, :conditions => { :hidden => false }
  named_scope :by_platform, lambda { |platform| { :conditions => ["platform = ?", platform] } }
  named_scope :by_partner_id, lambda { |partner_id| { :conditions => ["partner_id = ?", partner_id] } }

  delegate :conversion_rate, :to => :primary_currency, :prefix => true
  delegate :store_id, :description, :age_rating, :file_size_bytes, :supported_devices, :supported_devices?, :released_at, :user_rating, :to => :primary_app_metadata, :allow_nil => true

  # TODO: remove these columns from apps table definition and remove this method
  TO_BE_DELETED = %w(description price store_id age_rating file_size_bytes supported_devices released_at user_rating categories)
  def self.columns
    super.reject do |c|
      TO_BE_DELETED.include?(c.name)
    end
  end

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
    PLATFORM_DETAILS[platform][:store_url].sub('STORE_ID', store_id.to_s)
  end

  def primary_category
    categories.first.humanize if categories.present?
  end

  def info_url
    PLATFORM_DETAILS[platform][:info_url].sub('STORE_ID', store_id.to_s)
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
  # Grab data from the app store and update app and metadata objects.
  def update_from_store(app_store_id, country=nil)
    data = AppStore.fetch_app_by_id(app_store_id, platform, country)
    if (data.nil?) # might not be available in the US market
      data = AppStore.fetch_app_by_id(app_store_id, platform, primary_country)
    end
    raise "Fetching app store data failed for app: #{name} (#{id})." if data.nil?
    fill_app_store_data(data)
    data
  end

  def fill_app_store_data(data)
    self.name = data[:title]
    self.countries_blacklist = AppStore.prepare_countries_blacklist(store_id, platform)
    download_icon(data[:icon_url]) unless new_record?
  end

  def download_icon(url)
    return if url.blank?

    begin
      icon_src_blob = Downloader.get(url, :timeout => 30)
    rescue Exception => e
      Rails.logger.info "Failed to download icon for url: #{url}. Error: #{e}"
      Notifier.alert_new_relic(AppDataFetchError, "icon url #{url} for app id #{id}. Error: #{e}")
    else
      primary_offer.save_icon!(icon_src_blob)
    end
  end

  def get_icon_url(options = {})
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(id)}.merge(options))
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

  def price
    primary_app_metadata.nil? ? 0 : primary_app_metadata.price
  end

  def categories
    primary_app_metadata.nil? ? [] : primary_app_metadata.categories
  end

  def find_or_initialize_app_metadata(app_store_id)
    app_metadata = AppMetadata.find_by_store_name_and_store_id(store_name, app_store_id)
    if app_metadata.nil?
      app_metadata = AppMetadata.new(
        :store_name => store_name,
        :store_id => app_store_id
      )
    end
    app_metadata
  end

  def update_app_metadata(app_store_id)
    app_metadata = primary_app_metadata
    if app_metadata.nil?
      # app changed from not live to live status, need to create metadata record
      app_metadata = find_or_initialize_app_metadata(app_store_id)
      app_metadatas << app_metadata
    else
      if app_metadata.store_id != app_store_id
        # app_metadata record points to the wrong store_id -- update to correct record, creating if necessary
        app_metadata = find_or_initialize_app_metadata(app_store_id)
        app_metadata.save! if app_metadata.new_record?

        mapping = app_metadata_mappings.first
        mapping.app_metadata_id = app_metadata.id
        mapping.save!
        # do we need to remove any app_metadatas records that are no longer associated to any apps?
      end
    end
    app_metadata
  end

  def update_primary_app_metadata
    primary_app_metadata.update_metadata_from_store if primary_app_metadata.present?
  end

  def wifi_required?
    !!(file_size_bytes && file_size_bytes > PLATFORM_DETAILS[platform][:cell_download_limit_bytes])
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
    offer.wifi_only = wifi_required?
    offer.save!
  end

  def update_offers
    change_in_price = false
    change_in_store_id = false
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed? && name_was == offer.name
      if offer.price != price
        change_in_price = true
        offer.price = price
        offer.bid = offer.min_bid if offer.bid < offer.min_bid
        offer.bid = offer.max_bid if offer.bid > offer.max_bid
      end
      if offer.third_party_data != store_id
        change_in_store_id = true
        offer.third_party_data = store_id
        offer.device_types = get_offer_device_types.to_json
      end
      offer.url = store_url if change_in_store_id && !offer.url_overridden?
      offer.age_rating = age_rating if offer.age_rating != age_rating
      offer.hidden = hidden if hidden_changed?
      offer.tapjoy_enabled = false if hidden? && hidden_changed?
      offer.wifi_only = wifi_required? if offer.wifi_only != wifi_required?
      offer.save! if offer.changed?
    end

    action_offers.each do |action_offer|
      action_offer.partner_id = partner_id if partner_id_changed?
      action_offer.hidden = hidden if hidden_changed?
      action_offer.save! if action_offer.changed? || change_in_price || change_in_store_id
    end

    if (name_changed? || change_in_store_id || partner_id_changed?) && rating_offer.present?
      rating_offer.partner_id = partner_id if partner_id_changed?
      rating_offer.save!
    end
  end

  def update_currencies
    if partner_id_changed?
      currencies.each do |currency|
        currency.partner_id = partner_id
        currency.set_values_from_partner_and_reseller
        currency.save!
      end
    end
  end
end
