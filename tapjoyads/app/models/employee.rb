class Employee < ActiveRecord::Base
  include UuidPrimaryKey

  DEPARTMENTS = %w( products marketing sales )

  has_many :app_reviews, :as => :author

  validates_presence_of :first_name, :last_name, :title, :email
  validates_uniqueness_of :email
  validates_uniqueness_of :desk_location, :allow_blank => true
  validates_inclusion_of :department, :in => DEPARTMENTS, :allow_nil => true

  named_scope :active_by_first_name, :conditions => 'active = true', :order => 'first_name, last_name'
  named_scope :all_ordered, :order => 'department, last_name, first_name'
  named_scope :products_team, :conditions => [ 'active = ? and department = ?', true, 'products' ]

  has_one :user, :primary_key => :email, :foreign_key => :email
  has_many :wfhs

  def location
    desk_location.split(',').map(&:to_i) unless desk_location.blank?
  end

  def location=(array)
    array = JSON.load(array) if String === array
    raise "location must be array" unless Array === array && array.length == 2
    self.desk_location = array.map(&:to_i).join(',')
  end

  def is_user?(user)
    email == user.email
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def dom_id
    full_name.gsub(/\W/, '').downcase
  end

  def photo_alt_name
    "#{first_name.downcase}_#{last_name.downcase}"
  end

  def get_avatar_url
    "https://secure.gravatar.com/avatar/#{generate_gravatar_hash}?d=mm&s=123"
  end

  def generate_gravatar_hash
    Digest::MD5.hexdigest email.strip.downcase
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
    CloudFront.invalidate(id, "employee_photos/#{id}.png") if existing_photo_blob.present?
  end

end
