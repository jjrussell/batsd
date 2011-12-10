class Employee < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :app_reviews, :as => :author

  validates_presence_of :first_name, :last_name, :title, :email, :superpower, :current_games, :weapon, :biography
  validates_uniqueness_of :email

  named_scope :active_only, :conditions => 'active = true', :order => 'display_order desc, last_name, first_name'
  named_scope :active_by_first_name, :conditions => 'active = true', :order => 'first_name, last_name'

  def full_name
    "#{first_name} #{last_name}"
  end

  def photo_alt_name
    "#{first_name.downcase}_#{last_name.downcase}"
  end

  def get_photo_url(options = {})
    source   = options.delete(:source)   { :s3 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    prefix = source == :s3 ? "https://s3.amazonaws.com/#{BucketNames::TAPJOY}" : CLOUDFRONT_URL

    "#{prefix}/employee_photos/#{id}.png"
  end

  def save_photo!(photo_src_blob)
    bucket = S3.bucket(BucketNames::TAPJOY)
    object = bucket.objects["employee_photos/#{id}.png"]

    existing_photo_blob = object.exists? ? object.read : ''

    return if Digest::MD5.hexdigest(photo_src_blob) == Digest::MD5.hexdigest(existing_photo_blob)

    photo = Magick::Image.from_blob(photo_src_blob)[0].resize(78, 78)
    photo_blob = photo.to_blob{|i| i.format = 'PNG'}

    object.write(:data => photo_blob, :acl => :public_read)
    CloudFront.invalidate("employee_photos/#{id}.png") if existing_photo_blob.present?
  end

end
