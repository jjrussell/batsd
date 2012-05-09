class ShortUrl < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :token
  validates_uniqueness_of :token

  before_validation :generate_token, :on => :create

  BASE_PATH = "#{WEBSITE_URL}/confirm/redirect/"

  def self.shorten(long_url, expiry = nil, token = nil)
    short_url = self.new(:long_url => long_url, :expiry => expiry, :token => token)
    short_url.save
    short_url
  end

  def generate_token
    self.token = Authlogic::Random.friendly_token if self.new_record? and self.token.nil?
  end

  def url
    BASE_PATH + token
  end
end
