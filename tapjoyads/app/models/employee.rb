class Employee < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :first_name, :last_name, :title, :email, :superpower, :current_games, :weapon, :biography
  validates_uniqueness_of :email
  
  named_scope :active_only, :conditions => 'active = true', :order => 'last_name, first_name'
  
  def full_name
    first_name + " " + last_name + ", " + title
  end
  
  def photo_alt_name
    first_name + "_" + last_name
  end
  
  def get_photo_url(options = {})
    source   = options.delete(:source)   { :s3 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL
    
    "#{prefix}/employee_photos/#{id}.png"
  end
  
  def save_photo!(photo_src_blob)
    bucket = S3.bucket(BucketNames::TAPJOY)
    
    existing_photo_blob = bucket.get("employee_photos/#{id}.png") rescue ''
    
    return if Digest::MD5.hexdigest(photo_src_blob) == Digest::MD5.hexdigest(existing_photo_blob)
    
    photo = Magick::Image.from_blob(photo_src_blob)[0].resize(136, 199)
    photo_blob = photo.to_blob{|i| i.format = 'PNG'}
  
    bucket.put("employee_photos/#{id}.png", photo_blob, {}, "public-read")
  
    # Invalidate cloudfront
    if existing_photo_blob.present?
      begin
        acf = RightAws::AcfInterface.new
        acf.invalidate('E1MG6JDV6GH0F2', ["/employee_photos/#{id}.png"], "#{id}.#{Time.now.to_i}")
      rescue Exception => e
        Notifier.alert_new_relic(FailedToInvalidateCloudfront, e.message)
      end
    end
  end
end
