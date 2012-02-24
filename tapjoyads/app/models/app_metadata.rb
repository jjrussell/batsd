class AppMetadata < ActiveRecord::Base
  include UuidPrimaryKey

  PLATFORMS = {'App Store' => 'iphone', 'Market' => 'android', 'Marketplace' => 'windows'}
  RATING_THRESHOLD = 0.6

  has_many :app_metadata_mappings
  has_many :apps, :through => :app_metadata_mappings
  has_many :app_reviews

  validates_presence_of :store_name, :store_id
  validates_uniqueness_of :store_id, :scope => [ :store_name ]
  validates_numericality_of :thumbs_up, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :thumbs_down, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false

  after_update :update_apps

  def categories=(arr)
    super(arr.join(';'))
  end

  def categories
    super.to_s.split(';')
  end

  def update_from_store
    data = AppStore.fetch_app_by_id(store_id, PLATFORMS[store_name])
    raise "Fetching app store data failed for app: #{name} (#{id})." if data.nil?

    fill_app_store_data(data)
    self.save!

    apps.each do |app|
      app.fill_app_store_data(data)
      app.save!
    end
  end

  def fill_app_store_data(data)
    self.name                = data[:title]
    self.price               = (data[:price].to_f * 100).round
    self.description         = data[:description]
    self.age_rating          = data[:age_rating]
    self.file_size_bytes     = data[:file_size_bytes]
    self.released_at         = data[:released_at]
    self.user_rating         = data[:user_rating]
    self.categories          = data[:categories]
    self.supported_devices   = data[:supported_devices].present? ? data[:supported_devices].to_json : nil
  end

  def total_thumbs_count
    thumbs_up + thumbs_down
  end

  def positive_thumbs_percentage
    total = total_thumbs_count
    total > 0 ? ((thumbs_up.to_f / total) * 100).round(2) : 0
  end

  private

  def update_apps
    if price_changed? || age_rating_changed? || file_size_bytes_changed?
      apps.each do |app|
        app.update_offers
        app.update_action_offers if price_changed?
      end
    end
  end
end
