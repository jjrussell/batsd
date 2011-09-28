class Gamer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :gamer_devices
  has_one :gamer_profile

  validates_associated :gamer_profile, :on => :create
  validates_presence_of :email
  attr_accessor :terms_of_service
  validates_acceptance_of :terms_of_service, :on => :create, :allow_nil => false
  
  before_create :generate_confirmation_token
  before_create :check_referrer
  
  alias_method :devices, :gamer_devices
  
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.perishable_token_valid_for = 1.hour
    c.login_field = :email
    c.validate_login_field = false
    c.require_password_confirmation = false
  end
  
  def confirm!
    self.confirmed_at = Time.zone.now
    save
  end
  
private

  def generate_confirmation_token
    self.confirmation_token = Authlogic::Random.friendly_token
  end
  
  def check_referrer
    if referrer.starts_with?('tjreferrer:')
      click = Click.new :key => referrer.gsub('tjreferrer:', '')
      if click.rewardable?
        device = Device.new :key => click.udid
        device.product = click.device_name
        device.save
        devices.build(:device => device)
        url = "#{API_URL}/offer_completed?click_key=#{click.key}"
        Downloader.get_with_retry url
      end
    end
  end
end
