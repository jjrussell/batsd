# == Schema Information
#
# Table name: app_metadatas
#
#  id                  :string(36)      not null, primary key
#  name                :string(255)
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
  def self.table_name
    "app_metadatas"
  end
  include UuidPrimaryKey
  json_set_field :countries_blacklist

  PLATFORMS = {'App Store' => 'iphone', 'Google Play' => 'android', 'Marketplace' => 'windows'}
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
    self.countries_blacklist = AppStore.prepare_countries_blacklist(store_id, PLATFORMS[store_name])
    self.languages           = data[:languages]
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
