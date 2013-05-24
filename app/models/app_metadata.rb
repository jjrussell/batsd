# == Schema Information
#
# Table name: app_metadatas
#
#  id                  :string(36)      not null, primary key
#  name                :string(255)
#  developer           :string(255)
#  description         :text
#  price               :integer(4)      default(0)
#  store_name          :string(255)     not null
#  store_id            :string(255)     not null
#  age_rating          :integer(4)
#  file_size_bytes     :integer(4)
#  supported_devices   :string(255)
#  released_at         :datetime
#  user_rating         :float
#  categories          :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  papaya_user_count   :integer(4)
#  thumbs_up           :integer(4)      default(0)
#  thumbs_down         :integer(4)      default(0)
#  countries_blacklist :text
#

class AppMetadata < ActiveRecord::Base
  include OfferParentIconMethods

  def self.table_name
    "app_metadatas"
  end
  include UuidPrimaryKey
  json_set_field :countries_blacklist, :screenshots

  RATING_THRESHOLD = 0.6

  has_many :app_metadata_mappings
  has_many :apps, :through => :app_metadata_mappings
  has_many :offers
  has_many :app_reviews

  validates_presence_of :store_name, :store_id
  validates_uniqueness_of :store_id, :scope => [ :store_name ]
  validates_numericality_of :price, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :file_size_bytes, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :user_rating, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :thumbs_up, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :thumbs_down, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_inclusion_of :store_name, :in => AppStore::SUPPORTED_STORES.keys

  after_update :update_offers

  def categories=(arr)
    super(arr.join(';'))
  end

  def categories
    super.to_s.split(';')
  end

  def update_from_store(country = nil)
    begin
      data = AppStore.fetch_app_by_id(store_id, store.platform, store.id, country)
      # TODO: fix this: if data.nil? # might not be available in the US market
      # TODO: fix this: data = AppStore.fetch_app_by_id(store_id, platform, primary_country)
    rescue Patron::HostResolutionError, RuntimeError
    end
    raise "Fetching app store data failed for app: #{name} (#{id})." if data.nil?

    fill_app_store_data(data)
    download_and_save_icon!(data[:icon_url])
    save_screenshots(data[:screenshot_urls])
    self.save!

    app_metadata_mappings.each do |mapping|
      if mapping.is_primary
        mapping.app.fill_app_store_data(data)
        mapping.app.save!
      end
    end
    data
  end

  def hashed_blob(checksum)
    Digest::SHA2.hexdigest("#{id}#{checksum}")
  end

  def total_thumbs_count
    thumbs_up + thumbs_down
  end

  def positive_thumbs_percentage
    total = total_thumbs_count
    total > 0 ? ((thumbs_up.to_f / total) * 100).round(2) : 0
  end

  def info_url(app_store_id=nil)
    store.info_url.sub('STORE_ID', (app_store_id || store_id).to_s)
  end

  def store_url
    store.store_url.sub('STORE_ID', store_id.to_s)
  end

  def store
    AppStore.find(store_name)
  end

  def wifi_required?
    download_limit = App::PLATFORM_DETAILS[store.platform][:cell_download_limit_bytes]
    !!(file_size_bytes && file_size_bytes > download_limit)
  end

  def is_ipad_only?
    supported_devices? && JSON.load(supported_devices).all?{ |i| i.match(/^ipad/i) }
  end

  def get_offer_device_types
    is_ipad_only? ? Offer::IPAD_DEVICES : App::PLATFORM_DETAILS[store.platform][:expected_device_types]
  end

  def recently_released?
    released_at? && (Time.zone.now - released_at) < 7.day
  end

  def bad_rating?
    user_rating && user_rating < 3.0
  end

  def primary_category
    categories.first.humanize if categories.present?
  end

  def save_screenshots(screenshot_urls)
    return if screenshot_urls.nil? || screenshot_urls.empty?
    new_screenshots = []
    screenshot_urls.each do |screenshot_url|
      screenshot_blob = download_blob(screenshot_url)
      next if screenshot_blob.nil?

      screenshot_hash = hashed_blob(Digest::MD5.hexdigest(screenshot_blob))
      new_screenshots << screenshot_hash
      upload_screenshot(screenshot_blob, screenshot_hash) unless self.get_screenshots.include?(screenshot_hash)
    end

    delete_screenshots(self.get_screenshots - new_screenshots)
    self.screenshots = new_screenshots
    save! if changed?
  end

  def in_network_app_metadata(options = {})
    {
      :name => name,
      :description => description,
      :screenshots => get_screenshots_urls,
      :icon_url => IconHandler.get_icon_url(options.merge(:icon_id => IconHandler.hashed_icon_id(id))),
      :developer => developer,
      :price => price,
      :age_rating => age_rating,
      :user_rating => user_rating,
      :categories => categories,
      :external_store_name => store_name,
      :external_store_key => store_id,
      :file_size_bytes => file_size_bytes,
    }
  end

  def get_screenshots_urls
    screenshots_urls = []
    return screenshots_urls unless self.screenshots
    begin
      JSON::parse(self.screenshots).each do |screenshot_name|
        screenshots_urls << "https://s3.amazonaws.com/#{BucketNames::APP_SCREENSHOTS}/app_store/original/#{screenshot_name}"
      end
    rescue JSON::ParserError
    end
    screenshots_urls
  end

  private

  def download_and_save_icon!(url)
    return if url.blank? || offers.blank?
    icon_src_blob = download_blob(url)
    save_icon!(icon_src_blob) if icon_src_blob
  end

  def download_blob(url)
    return nil if url.blank?
    begin
      Downloader.get(url, :timeout => 30)
    rescue Exception => e
      Rails.logger.info "Failed to download screenshot blob from url: #{url}. Error: #{e}"
      Notifier.alert_new_relic(AppDataFetchError, "image url #{url} for app id #{id}. Error: #{e}")
      return nil
    end
  end

  def delete_screenshots(screenshot_names)
    screenshot_names.each do |screenshot_name|
      S3.bucket(BucketNames::APP_SCREENSHOTS).objects["app_store/original/#{screenshot_name}"].delete
    end
  end

  def upload_screenshot(blob, screenshot_name)
    S3.bucket(BucketNames::APP_SCREENSHOTS).objects["app_store/original/#{screenshot_name}"].write(:data => blob, :acl => :public_read)
  end

  def update_offers
    if name_changed? || price_changed? || age_rating_changed? || file_size_bytes_changed?
      offers.each do |offer|
        offer.update_from_app_metadata(self)
      end
    end
  end

  def fill_app_store_data(data)
    blacklist = AppStore.prepare_countries_blacklist(store_id, store.platform)
    self.name                = data[:title]
    self.price               = (data[:price].to_f * 100).round
    self.description         = data[:description]
    self.age_rating          = data[:age_rating]
    self.file_size_bytes     = data[:file_size_bytes]
    self.released_at         = data[:released_at]
    self.user_rating         = data[:user_rating]
    self.categories          = data[:categories]
    self.supported_devices   = data[:supported_devices].present? ? data[:supported_devices].to_json : nil
    self.countries_blacklist = blacklist unless blacklist.nil?
    self.languages           = data[:languages]
    self.developer           = data[:publisher]
  end
end
