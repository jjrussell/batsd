class ShortUrl < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :token
  validates_uniqueness_of :token

  def self.shorten(url, expiry = nil, token = nil)
    short_url =  self.new(:url => url, :expiry => expiry, :token => token)
    return short_url.url if short_url.save()
    url
  end

  def before_validation_on_create
    self.token = Authlogic::Random.friendly_token if self.new_record? and self.token.nil?
  end
end
