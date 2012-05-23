class App < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  acts_as_trackable :third_party_data => :store_id, :age_rating => :age_rating, :wifi_only => :wifi_required?, :device_types => lambda { get_offer_device_types.to_json }, :url => :store_url

  ALLOWED_PLATFORMS = { 'android' => 'Android', 'iphone' => 'iOS', 'windows' => 'Windows' }
  BETA_PLATFORMS    = {}
  PLATFORMS         = ALLOWED_PLATFORMS.merge(BETA_PLATFORMS)
  APPSTORE_COUNTRIES_OPTIONS = GeoIP::CountryName.zip(GeoIP::CountryCode).select do |name, code|
      code.match(/[A-Z]{2}/) && code != 'KP'
    end.map do |name, code|
      ["#{code} -- #{name}", code]
    end.sort
  WINDOWS_ACCEPT_LANGUAGES = Set.new(%w(
      es-ar en-au nl-be fr-be pt-br en-ca fr-ca es-cl es-co cs-cz da-dk de-de
      es-es fr-fr en-hk en-in id-id en-ie it-it hu-hu ms-my es-mx nl-nl en-nz
      nb-no de-at es-pe en-ph pl-pl pt-pt de-ch en-sg en-za fr-ch fi-fi sv-se
      en-gb en-us zh-cn el-gr zh-hk ja-jp ko-kr ru-ru zh-tw
    ))
  WINDOWS_ACCEPT_LANGUAGES_OPTIONS = WINDOWS_ACCEPT_LANGUAGES.map do |pair|
    country_index = GeoIP::CountryCode.index(pair[3, 2].upcase)
    country_name = GeoIP::CountryName[country_index]
    [ "#{country_name} - #{pair[0, 2]}", pair ]
  end.sort
  PLATFORM_DETAILS = {
    'android' => {
      :expected_device_types => Offer::ANDROID_DEVICES,
      :sdk => {
        :connect  => ANDROID_CONNECT_SDK,
        :offers   => ANDROID_OFFERS_SDK,
        :vg       => ANDROID_VG_SDK,
      },
      :store_name => 'Google Play',
      :info_url => 'https://play.google.com/store/apps/details?id=STORE_ID',
      :store_url => 'market://search?q=STORE_ID',
      :default_actions_file_name => "TapjoyPPA.java",
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
      :versions => [ '2.0', '2.1', '2.2', '3.0', '3.1', '3.2', '4.0', '4.1', '4.2', '4.3', '5.0' ],
      :cell_download_limit_bytes => 50.megabytes
    },
    'windows' => {
      :expected_device_types => Offer::WINDOWS_DEVICES,
      :sdk => {
        :connect  => WINDOWS_CONNECT_SDK,
        :offers   => WINDOWS_OFFERS_SDK,
        :vg       => WINDOWS_OFFERS_SDK,
      },
      :store_name => 'Marketplace',
      :info_url => 'http://windowsphone.com/s?appId=STORE_ID',
      :store_url => 'http://social.zune.net/redirect?type=phoneapp&id=STORE_ID',
      :default_actions_file_name => '', #TODO fill this out
      :versions => [ '7.0' ],
      :cell_download_limit_bytes => 20.megabytes
    },
  }

  TRADEDOUBLER_COUNTRIES = Set.new(%w( GB FR DE IT IE ES NL AT CH BE DK FI NO SE LU PT GR ))
  MAXIMUM_INSTALLS_PER_PUBLISHER = 4000
  PREVIEW_PUBLISHER_APP_ID = "bba49f11-b87f-4c0f-9632-21aa810dd6f1" # EasyAppPublisher... used for "ad preview" generation

  attr_accessor :store_id_changed

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_app_id
  has_many :currencies, :order => 'ordinal ASC'
  has_one :primary_currency, :class_name => 'Currency', :conditions => 'id = app_id'
  has_one :rating_offer
  has_many :rewarded_featured_offers, :class_name => 'Offer', :as => :item, :conditions => "featured AND rewarded"
  has_one :primary_rewarded_featured_offer, :class_name => 'Offer', :as => :item, :conditions => "featured AND rewarded", :order => "created_at"
  has_many :non_rewarded_featured_offers, :class_name => 'Offer', :as => :item, :conditions => "featured AND NOT rewarded"
  has_one :primary_non_rewarded_featured_offer, :class_name => 'Offer', :as => :item, :conditions => "featured AND NOT rewarded", :order => "created_at"
  has_many :action_offers
  has_many :deeplink_offers
  has_many :non_rewarded_offers, :class_name => 'Offer', :as => :item, :conditions => "NOT rewarded AND NOT featured"
  has_one :primary_non_rewarded_offer, :class_name => 'Offer', :as => :item, :conditions => "NOT rewarded AND NOT featured", :order => "created_at"
  has_many :app_metadata_mappings
  has_many :app_metadatas, :through => :app_metadata_mappings, :readonly => false
  has_one :primary_app_metadata,
    :through => :app_metadata_mappings,
    :source => :app_metadata,
    :order => "created_at"
  has_many :reengagement_offers

  belongs_to :partner

  set_callback :cache_associations, :before, :primary_app_metadata
  set_callback :cache_associations, :before, :app_metadatas

  validates_presence_of :partner, :name, :secret_key
  validates_inclusion_of :platform, :in => PLATFORMS.keys
  validates_numericality_of :active_gamer_count, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false

  before_validation :generate_secret_key, :on => :create

  after_create :create_primary_offer
  after_update :update_all_offers
  after_update :update_currencies
  after_save :clear_dirty_flags

  scope :visible, :conditions => { :hidden => false }
  scope :by_platform, lambda { |platform| { :conditions => ["platform = ?", platform] } }
  scope :by_partner_id, lambda { |partner_id| { :conditions => ["partner_id = ?", partner_id] } }
  scope :live, :joins => [ :app_metadatas ], :conditions =>
    "#{AppMetadata.quoted_table_name}.store_id IS NOT NULL"

  delegate :conversion_rate, :to => :primary_currency, :prefix => true
  delegate :store_id, :store_id?, :description, :age_rating, :file_size_bytes, :supported_devices, :supported_devices?,
    :released_at, :released_at?, :user_rating, :get_countries_blacklist, :countries_blacklist,
    :to => :primary_app_metadata, :allow_nil => true
  delegate :name, :dashboard_partner_url, :to => :partner, :prefix => true

  memoize :partner_name, :partner_dashboard_partner_url

  def is_ipad_only?
    supported_devices? && JSON.load(supported_devices).all?{ |i| i.match(/^ipad/i) }
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

  def build_reengagement_offer(options = {})
    default_options = {
      :partner => partner,
      :day_number => reengagement_campaign.length,
    }
    reengagement_offers.build(options.merge(default_options))
  end

  def reengagement_campaign
    reengagement_offers.visible.order_by_day
  end

  def enable_reengagement_campaign!
    update_reengagements_with_enable_or_disable(true)
  end

  def disable_reengagement_campaign!
    update_reengagements_with_enable_or_disable(false)
  end

  def reengagement_campaign_from_cache
    ReengagementOffer.find_all_in_cache_by_app_id(id)
  end

  ##
  # Grab data from the app store and update app and metadata objects.
  def update_from_store(params)
    store_id = params.delete(:store_id)
    country  = params.delete(:country)
    return false if store_id.blank?

    app_metadata = update_app_metadata(store_id) || primary_app_metadata
    begin
      data = AppStore.fetch_app_by_id(store_id, platform, country)
      if (data.nil?) # might not be available in the US market
        data = AppStore.fetch_app_by_id(store_id, platform, primary_country)
      end
    rescue Patron::HostResolutionError, RuntimeError
      return false
    end
    return false if data.nil?

    fill_app_store_data(data)
    app_metadata.fill_app_store_data(data)
    return false unless app_metadata.save

    data
  end

  def queue_store_update(app_store_id)
    app_metadata = update_app_metadata(app_store_id) || primary_app_metadata
    if app_metadata.save
      Sqs.send_message(QueueNames::GET_STORE_INFO, app_metadata.id)
      true
    else
      false
    end
  end

  def fill_app_store_data(data)
    self.name = data[:title]
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

  def formatted_active_gamer_count(increment = 1000, max = 10000)
    return active_gamer_count if active_gamer_count <= increment

    rounded = [ active_gamer_count - (active_gamer_count % increment), max ].min

    "#{rounded}+"
  end

  def can_have_new_currency?
    !currencies.any?(&:has_special_callback?)
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
    primary_app_metadata ? primary_app_metadata.price : 0
  end

  def categories
    primary_app_metadata ? primary_app_metadata.categories : []
  end

  def update_app_metadata(app_store_id)
    if !app_metadatas.map(&:store_id).include?(app_store_id)
      # app currently has no app_metadata or associated with a different instance
      app_metadatas.delete_all
      app_metadata = AppMetadata.find_or_initialize_by_store_name_and_store_id(App::PLATFORM_DETAILS[platform][:store_name], app_store_id)
      add_app_metadata(app_metadata)
    end
    app_metadata
  end

  def add_app_metadata(metadata)
    app_metadatas << metadata
    self.store_id_changed = true
  end

  def wifi_required?
    download_limit = PLATFORM_DETAILS[platform][:cell_download_limit_bytes]
    !!(file_size_bytes && file_size_bytes > download_limit)
  end

  def update_promoted_offers(offer_ids)
    success = true
    currencies.each { |currency| success &= currency.update_promoted_offers(offer_ids)}
    success
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id
      offer.name = name if name_changed? && name_was == offer.name
      offer.price = price
      offer.bid = offer.min_bid if offer.bid < offer.min_bid
      offer.bid = offer.max_bid if offer.bid > offer.max_bid
      offer.third_party_data = store_id
      offer.device_types = get_offer_device_types.to_json if store_id_changed
      offer.url = store_url unless offer.url_overridden?
      offer.age_rating = age_rating
      offer.hidden = hidden
      offer.tapjoy_enabled = false if hidden?
      offer.wifi_only = wifi_required?
      offer.save! if offer.changed?
    end
  end

  def update_rating_offer
    rating_offer.partner_id = partner_id
    rating_offer.save!
  end

  def update_action_offers
    action_offers.each do |action_offer|
      action_offer.partner_id = partner_id
      action_offer.hidden = hidden
      action_offer.save!
    end
  end

  def test_offer
    test_offer = Offer.new(
      :item_id            => id,
      :item_type          => 'TestOffer',
      :name               => 'Test Offer (Visible to Test Devices)',
      :third_party_data   => id,
      :price              => 0,
      :reward_value       => 100)
    test_offer.id = id
    test_offer
  end

  def test_video_offer
    test_video_offer = VideoOffer.new(
      :name       => 'Test Video Offer (Visible to Test Devices)',
      :partner_id => partner_id,
      :video_url  => 'https://s3.amazonaws.com/tapjoy/videos/src/test_video.mp4')
    test_video_offer.id = 'test_video'

    primary_offer = Offer.new(
      :item_id          => 'test_video',
      :name             => 'Test Video Offer (Visible to Test Devices)',
      :url              => 'https://s3.amazonaws.com/tapjoy/videos/src/test_video.mp4',
      :reward_value     => 100,
      :third_party_data => '')
    primary_offer.id = 'test_video'

    test_video_offer.primary_offer           = primary_offer
    test_video_offer.primary_offer.item_type = 'TestVideoOffer'
    test_video_offer
  end

  # For use within TJM (since dashboard URL helpers aren't available within TJM)
  def dashboard_app_url
    uri = URI.parse(DASHBOARD_URL)
    "#{uri.scheme}://#{uri.host}/apps/#{self.id}"
  end

  private

  def update_reengagements_with_enable_or_disable(enable)
    return if reengagement_campaign.empty?
    self.reengagement_campaign_enabled = enable
    self.save!
    reengagement_campaign.map(&:update_offers)
  end


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
    clear_association_cache
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

  def update_all_offers
    clear_association_cache
    update_offers if store_id_changed || partner_id_changed? || name_changed? || hidden_changed?
    update_rating_offer if rating_offer.present? && (store_id_changed || partner_id_changed? || name_changed?)
    update_action_offers if store_id_changed || partner_id_changed? || hidden_changed?
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

  def clear_dirty_flags
    self.store_id_changed = false
  end
end
