class Gamer < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :gamer_devices, :dependent => :destroy
  has_many :invitations, :dependent => :destroy
  has_one :gamer_profile, :dependent => :destroy
  delegate :facebook_id, :facebook_id?, :fb_access_token, :referred_by, :referred_by=, :referred_by?, :referral_count, :to => :gamer_profile, :allow_nil => true

  validates_associated :gamer_profile, :on => :create
  validates_presence_of :email
  attr_accessor :terms_of_service
  validates_acceptance_of :terms_of_service, :on => :create, :allow_nil => false

  before_create :generate_confirmation_token
  before_create :check_referrer
  before_create :set_tos_version

  after_destroy :delete_friends

  DAYS_BEFORE_DELETION = 3.days
  named_scope :to_delete, lambda {
    {
      :conditions => ["deactivated_at < ?", Time.zone.now.beginning_of_day - DAYS_BEFORE_DELETION],
      :order => 'deactivated_at'
    }
  }

  alias_method :devices, :gamer_devices

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.perishable_token_valid_for = 1.day
    c.login_field = :email
    c.validate_login_field = false
    c.require_password_confirmation = true
  end

  def confirm!
    self.confirmed_at = Time.zone.now
    save
  end

  def deactivate!
    self.deactivated_at = Time.zone.now
    save!
  end

  def external_info(channel)
    case channel
    when Invitation::EMAIL
      email
    when Invitation::FACEBOOK
      facebook_id
    when Invitation::TWITTER
      twitter_id
    end
  end

  def self.find_all_gamer_based_on_channel(channel, external)
    gamer_profiles = []
    gamers = []
    
    case channel
    when Invitation::FACEBOOK
      gamer_profiles = GamerProfile.find_all_by_facebook_id(external)
    when Invitation::TWITTER
      gamers = Gamer.find_all_by_twitter_id(external)
    end

    if gamer_profiles.any?
      gamer_profiles.each do |profile|
        gamers << Gamer.find_by_id(profile.gamer_id)
      end
    end
    gamers
  end

  def follow_gamer(friend)
    Friendship.establish_friendship(id, friend.id)
  end

  def invitation_for(friend_id, channel)
    invitation = Invitation.find_by_external_info_and_gamer_id(friend_id, id)
    if invitation.nil?
      invitation = invitations.build(:channel => channel, :external_info => friend_id)
      invitation.save
    end
    invitation
  end

  def get_gamer_nickname
    if gamer_profile.present? && gamer_profile.nickname.present?
      gamer_profile.nickname
    elsif gamer_profile.present? && gamer_profile.name.present?
      gamer_profile.name
    end
  end

  def get_gamer_name
    if gamer_profile.present? && gamer_profile.name.present?
      gamer_profile.name
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

  def update_twitter_info!(authhash)
    if twitter_id != authhash[:twitter_id]
      self.twitter_id            = authhash[:twitter_id]
      self.twitter_access_token  = authhash[:twitter_access_token]
      self.twitter_access_secret = authhash[:twitter_access_secret]
      save!

      Invitation.reconcile_pending_invitations(Gamer.find_by_id(self.id), :external_info => twitter_id)
    end
  end

  def dissociate_account!(account_type)
    case account_type
    when Invitation::FACEBOOK
      self.gamer_profile.facebook_id     = nil
      self.gamer_profile.fb_access_token = nil
      self.gamer_profile.save!
    when Invitation::TWITTER
      self.twitter_id            = nil
      self.twitter_access_token  = nil
      self.twitter_access_secret = nil
      save!
    end
  end

  private

  def generate_gravatar_hash
    Digest::MD5.hexdigest email.strip.downcase
  end

  def check_referrer
    if referrer.present?
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
      else
        begin
          self.referred_by, invitation_id = SymmetricCrypto.decrypt_object(referrer, SYMMETRIC_CRYPTO_SECRET).split(',')
        rescue OpenSSL::Cipher::CipherError
        end
        if referred_by? && invitation_id
          referred_by_gamer = Gamer.find_by_id(self.referred_by)
          invitation = Invitation.find_by_id(invitation_id)
          if referred_by_gamer && invitation
            referred_by_gamer.gamer_profile.update_attributes!(:referral_count => referred_by_gamer.referral_count + 1)
            follow_gamer(Gamer.find_by_id(referred_by))
            Invitation.reconcile_pending_invitations(self, :invitation => invitation)
          end
        end
      end
    end
  end

  def generate_confirmation_token
    self.confirmation_token = Authlogic::Random.friendly_token
  end

  def set_tos_version
    self.accepted_tos_version = TAPJOY_GAMES_CURRENT_TOS_VERSION
  end

  def delete_friends
    conditions = "gamer_id = '#{id}' or following_id = '#{id}'"
    Friendship.select(:where => conditions, :consistent => true) do |friendship|
      friendship.delete_all
    end
  end
end
