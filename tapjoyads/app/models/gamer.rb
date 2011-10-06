class Gamer < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :gamer_devices
  has_many :invitations
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
    c.require_password_confirmation = true
  end

  def confirm!
    self.confirmed_at = Time.zone.now
    save
  end
  
  def update_facebook_info!(facebook_user)
    if facebook_id != facebook_user.id
      self.facebook_id = facebook_user.id
      self.fb_access_token = facebook_user.client.access_token
      save!

      Invitation.reconcile_pending_invitations(self, :external_info => facebook_id)
    end
  end

  def external_info(channel)
    case channel
    when Invitation::EMAIL
      email
    when Invitation::FACEBOOK
      facebook_id
    end
  end

  def follow_gamer(friend)
    Friendship.establish_friendship(id, friend.id)
  end

  def facebook_invitation_for(friend_id)
    invitation = Invitation.find_by_external_info_and_gamer_id(friend_id, id)
    if invitation.nil?
      invitation = invitations.build(:channel => Invitation::FACEBOOK, :external_info => friend_id)
      invitation.save
    end
    invitation
  end
  
  def get_gamer_name
    if gamer_profile.present? && ( gamer_profile.first_name.present? || gamer_profile.last_name.present? )
      if gamer_profile.first_name.blank?
        gamer_profile.last_name
      elsif gamer_profile.last_name.blank?
        gamer_profile.first_name
      else
        "#{gamer_profile.first_name} #{gamer_profile.last_name}"
      end
    else
      email
    end
  end

  def get_gravatar_profile_url
    "https://secure.gravatar.com/#{generate_gravatar_hash}"
  end

  def get_avatar_url(size=nil)
    size_param = size.present? ? "&size=#{size}" : nil
    "https://secure.gravatar.com/avatar/#{generate_gravatar_hash}?d=mm#{size_param}"
  end

private
  def generate_gravatar_hash
    Digest::MD5.hexdigest email.strip.downcase
  end

  def check_referrer
    if referrer?
      self.referred_by, invitation_id = SymmetricCrypto.decrypt_object(referrer, SYMMETRIC_CRYPTO_SECRET).split(',')
      if referred_by? && invitation_id
        Gamer.increment_counter(:referral_count, referred_by)
        invitation = Invitation.find_by_id(invitation_id)
        follow_gamer(Gamer.find_by_id(referred_by))
        Invitation.reconcile_pending_invitations(self, :invitation => invitation)
      end
    end
  end

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
