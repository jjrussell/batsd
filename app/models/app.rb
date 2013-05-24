class App < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  acts_as_trackable :third_party_data => :store_id, :age_rating => :age_rating, :wifi_only => :wifi_required?, :device_types => lambda { |ctx| get_offer_device_types.to_json }, :url => :store_url

  ALLOWED_PLATFORMS = {'android' => 'Android', 'iphone' => 'iOS'}
  BETA_PLATFORMS    = {'windows' => 'Windows'}
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
      :default_store_name => 'android.GooglePlay',
      :default_display_store_name => 'Google Play',
      :default_sdk_store_name => 'google',
      :default_actions_file_name => "TapjoyPPA.java",
      :versions =>  %w( 1.5 1.6 2.0 2.1 2.2 2.3 3.0 3.1 3.2 4.0 4.1),
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
      :default_store_name => 'iphone.AppStore',
      :default_display_store_name => 'App Store',
      :default_actions_file_name => "TJCPPA.h",
      :versions => %w( 2.0 2.1 2.2 3.0 3.1 3.2 4.0 4.1 4.2 4.3 5.0 5.1 6.0 ),
      :cell_download_limit_bytes => 50.megabytes
    },
    'windows' => {
      :expected_device_types => Offer::WINDOWS_DEVICES,
      :sdk => {
        :connect  => WINDOWS_CONNECT_SDK,
        :offers   => WINDOWS_OFFERS_SDK,
        :vg       => WINDOWS_OFFERS_SDK,
      },
      :default_store_name => 'windows.Marketplace',
      :default_display_store_name => 'Marketplace',
      :default_actions_file_name => '', #TODO fill this out
      :versions => %w( 7.0 ),
      :cell_download_limit_bytes => 20.megabytes
    },
  }

  MAXIMUM_INSTALLS_PER_PUBLISHER = 4000
  PREVIEW_PUBLISHER_APP_ID = "bba49f11-b87f-4c0f-9632-21aa810dd6f1" # EasyAppPublisher... used for "ad preview" generation

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_app_id
  has_many :currencies, :order => 'ordinal ASC', :conditions => 'conversion_rate > 0'
  has_one :primary_currency, :class_name => 'Currency', :conditions => 'id = app_id'
  has_one :rating_offer
  has_many :rewarded_featured_offers, :class_name => 'Offer', :as => :item, :conditions => "featured AND rewarded"
  has_many :non_rewarded_featured_offers, :class_name => 'Offer', :as => :item, :conditions => "featured AND NOT rewarded"
  has_many :action_offers
  has_many :deeplink_offers
  has_many :non_rewarded_offers, :class_name => 'Offer', :as => :item, :conditions => "NOT rewarded AND NOT featured"
  has_many :app_metadata_mappings
  has_one :primary_app_metadata_mapping, :class_name => 'AppMetadataMapping', :conditions => 'is_primary = true'
  has_many :app_metadatas, :through => :app_metadata_mappings, :readonly => false
  has_one :primary_app_metadata,
    :through => :app_metadata_mappings,
    :source => :app_metadata,
    :conditions => "app_metadata_mappings.is_primary = true"
  has_many :reengagement_offers
  has_one :non_rewarded, :class_name => 'Currency', :conditions => {:conversion_rate => 0}

  belongs_to :partner
  belongs_to :experiment

  set_callback :cache_associations, :before, :primary_app_metadata
  set_callback :cache_associations, :before, :app_metadatas

  validates_presence_of :partner, :name, :secret_key
  validates_inclusion_of :platform, :in => PLATFORMS.keys
  validates_numericality_of :active_gamer_count, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false

  before_validation :generate_secret_key, :on => :create

  after_create :create_primary_offer
  after_update :update_all_offers
  after_update :update_currencies

  # before_save :update_kontagent
  before_destroy :delete_kontagent

  scope :visible, :conditions => { :hidden => false }
  scope :by_platform, lambda { |platform| { :conditions => ["platform = ?", platform] } }
  scope :by_partner_id, lambda { |partner_id| { :conditions => ["partner_id = ?", partner_id] } }
  scope :live, :joins => [ :app_metadatas ], :conditions =>
    "#{AppMetadata.quoted_table_name}.store_id IS NOT NULL"

  delegate :conversion_rate, :to => :primary_currency, :prefix => true
  delegate :store_name, :store_id, :store_id?, :description, :age_rating, :file_size_bytes, :supported_devices,
    :supported_devices?, :released_at, :released_at?, :user_rating, :get_countries_blacklist, :countries_blacklist,
    :languages, :info_url, :wifi_required?, :is_ipad_only?, :recently_released?, :bad_rating?, :primary_category,
    :to => :primary_app_metadata, :allow_nil => true
  delegate :name, :dashboard_partner_url, :to => :partner, :prefix => true

  memoize :partner_name, :partner_dashboard_partner_url


  def associated_offers(props = {})
    offers.reject do |offer|
      offer.id == self.id || (props.present? && props.detect() { |prop,val| offer.send(prop) != val })
    end
  end

  def primary_app_metadata_id
    self.primary_app_metadata.try(:id)
  end

  def tapjoy_enabled_associated_offers()
    associated_offers(:tapjoy_enabled => true)
  end

  def tapjoy_disabled_associated_offers
    associated_offers(:tapjoy_enabled => false)
  end

  def price
    primary_app_metadata ? primary_app_metadata.price : 0
  end

  def categories
    primary_app_metadata ? primary_app_metadata.categories : []
  end

  def get_offer_device_types
    primary_app_metadata ? primary_app_metadata.get_offer_device_types : App::PLATFORM_DETAILS[platform][:expected_device_types]
  end

  def store_url
    primary_app_metadata ? primary_app_metadata.store_url : AppStore.find(App::PLATFORM_DETAILS[platform][:default_store_name]).store_url
  end

  def primary_rewarded_featured_offer
    primary_app_metadata ? primary_app_metadata_mapping.primary_rewarded_featured_offer : offers.where(:featured => true, :rewarded => true).order(:created_at).first
  end

  def primary_non_rewarded_featured_offer
    primary_app_metadata ? primary_app_metadata_mapping.primary_non_rewarded_featured_offer : offers.where(:featured => true, :rewarded => false).order(:created_at).first
  end

  def primary_non_rewarded_offer
    primary_app_metadata ? primary_app_metadata_mapping.primary_non_rewarded_offer : offers.where(:featured => false, :rewarded => false).order(:created_at).first
  end

  def platform_name
    PLATFORMS[platform]
  end

  def virtual_goods
    VirtualGood.select(:where => "app_id = '#{self.id}'", :limit => 1000)[:items]
  end

  def has_virtual_goods?
    VirtualGood.count(:where => "app_id = '#{self.id}'") > 0
  end

  def default_url_scheme
    "tjc#{store_id.to_s}"
  end

  def launch_url
    protocol_handler.present? ? protocol_handler : default_url_scheme
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

  def build_non_rewarded
    options = {
      :conversion_rate  => 0,
      :callback_url     => Currency::NO_CALLBACK_URL,
      :name             => Currency::NON_REWARDED_NAME,
      :app_id           => self.id,
      :tapjoy_enabled   => false,
      :partner          => self.partner,
      :rev_share_override => 0.7
    }
    Currency.new(options)
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

  def update_app_metadata(store_name, store_id)
    app_metadata = app_metadatas.find_by_store_name(store_name)
    raise "update_app_metadata called with invalid #{store_name}" unless app_metadata.present?

    unless app_metadata.store_id == store_id
      mapping = app_metadata_mappings.find_by_app_metadata_id(app_metadata.id)
      mapping.app_metadata = AppMetadata.find_or_initialize_by_store_name_and_store_id(store_name, store_id)
      mapping.save!

      offers.find_all_by_app_metadata_id(app_metadata.id).each do |offer|
        offer.update_from_app_metadata(mapping.app_metadata, name)
      end
      action_offers.each do |action_offer|
        action_offer.update_offers_for_app_metadata(app_metadata, mapping.app_metadata)
      end

      app_metadata = mapping.app_metadata
    end
    app_metadata
  end

  def add_app_metadata(store_name, store_id, primary = false)
    return if primary && primary_app_metadata.present?
    return if !primary && !primary_app_metadata.present?
    return if app_metadatas.find_by_store_name(store_name).present?

    new_metadata = AppMetadata.find_or_initialize_by_store_name_and_store_id(store_name, store_id)
    new_metadata.save! if new_metadata.new_record?

    mapping = AppMetadataMapping.new
    mapping.app = self
    mapping.app_metadata = new_metadata
    mapping.is_primary = primary
    mapping.save!

    if primary
      offers.each do |offer|
        offer.update_from_app_metadata(mapping.app_metadata, name) unless offer.app_metadata
      end
      action_offers.each do |action_offer|
        action_offer.offers.each do |offer|
          offer.update_from_app_metadata(mapping.app_metadata) unless offer.app_metadata
        end
      end
      deeplink_offers.each do |deeplink_offer|
        deeplink_offer.offers.each do |offer|
          offer.icon_id_override = mapping.app_metadata.id
          offer.save! if offer.icon_id_override_changed?
        end
      end
    else
      create_primary_distribution_offer(mapping.app_metadata)
      create_action_offer_distributions(mapping.app_metadata)
    end

    mapping.app_metadata
  end

  def remove_app_metadata(app_metadata)
    return false if primary_app_metadata == app_metadata
    return false unless app_metadatas.include?(app_metadata)
    app_metadatas.delete(app_metadata)
    offers.find_all_by_app_metadata_id(app_metadata.id).each do |offer|
      offer.destroy
    end
    action_offers.each do |action_offer|
      action_offer.remove_offers_for_app_metadata(app_metadata)
    end
    true
  end

  def fill_app_store_data(data)
    self.name = data[:title]
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

  def sdk_url(type)
    PLATFORM_DETAILS[platform][:sdk][type]
  end

  def os_versions
    PLATFORM_DETAILS[platform][:versions]
  end

  def screen_layout_sizes
    PLATFORM_DETAILS[platform][:screen_layout_sizes].nil? ? [] : PLATFORM_DETAILS[platform][:screen_layout_sizes].sort{ |a,b| a[1] <=> b[1] }
  end

  def update_promoted_offers(offer_ids)
    success = true
    currencies.each { |currency| success &= currency.update_promoted_offers(offer_ids)}
    success
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

  def rewardable_currencies
    @rewardable_currencies ||= currencies.reject{ |c| c.conversion_rate <= 0 }
  end

  def videos_disabled?; not videos_enabled?; end

  def videos_cache_on?(connection)
    return false if videos_disabled?

    case connection
    when 'mobile' then videos_cache_3g?
    when 'wifi'   then videos_cache_wifi?
    else false
    end
  end

  def videos_stream_on?(connection)
    return false if videos_disabled?

    case connection
    when 'mobile' then videos_stream_3g?
    when 'wifi'   then true
    else false
    end
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
    offer.partner = partner
    offer.id = id
    if app_metadatas.present?
      offer.initialize_from_app_metadata(app_metadatas.first, name)
    else
      offer.initialize_from_app(self)
    end
    offer.save!
  end

  def create_primary_distribution_offer(app_metadata)
    clear_association_cache
    offer = Offer.new(:item => self)
    offer.partner = partner
    offer.initialize_from_app_metadata(app_metadata, name)
    offer.save!
  end

  def create_action_offer_distributions(app_metadata)
    action_offers.each do |action_offer|
      action_offer.create_offer_from_app_metadata(app_metadata)
    end
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id
      offer.name = name if app_metadatas.empty? && name_changed? && name_was == offer.name
      offer.hidden = hidden
      offer.tapjoy_enabled = false if hidden?
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

  def update_all_offers
    clear_association_cache
    update_offers if partner_id_changed? || name_changed? || hidden_changed?
    update_rating_offer if rating_offer.present? && (partner_id_changed? || name_changed?)
    update_action_offers if partner_id_changed? || hidden_changed?
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

  def update_kontagent
    if partner and partner.kontagent_enabled
      if KontagentHelpers.exists?(self)
        KontagentHelpers.update!(self) if kontagent_enabled and name_changed?
      else
        creation_response = KontagentHelpers.build!(self)
        self.kontagent_enabled = true
        self.kontagent_api_key = creation_response['api_key']
      end
    end
  end

  def delete_kontagent
    KontagentHelpers.delete!(self) if kontagent_enabled
  end
end
