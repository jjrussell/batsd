class Gamer < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :gamer_devices, :dependent => :destroy
  has_many :invitations, :dependent => :destroy
  has_many :gamer_reviews, :as => :author, :dependent => :destroy
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

  DAYS_BEFORE_DELETION = 3
  named_scope :to_delete, lambda {
    {
      :conditions => ["deactivated_at < ?", Time.zone.now.beginning_of_day - DAYS_BEFORE_DELETION.days],
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
    c.merge_validates_uniqueness_of_login_field_options(:case_sensitive => true)
    c.merge_validates_uniqueness_of_email_field_options(:case_sensitive => true)
  end

  def self.columns
    super.reject { |c| c.name == "use_gravatar" }
  end

  def confirm!
    self.confirmed_at = Time.zone.now
    save
  end

  def deactivate!
    self.deactivated_at = Time.zone.now
    save!
  end

  def reactivate!
    if self.deactivated_at?
      self.deactivated_at = nil
      save!
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

  def self.find_all_gamer_based_on_facebook(external)
    gamer_profiles = GamerProfile.find_all_by_facebook_id(external)
    gamers = []

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

  def facebook_invitation_for(friend_id)
    invitation = Invitation.find_by_external_info_and_gamer_id(friend_id, id)
    if invitation.nil?
      invitation = invitations.build(:channel => Invitation::FACEBOOK, :external_info => friend_id)
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

  def get_avatar_profile_url
    if gamer_profile.present? && gamer_profile.facebook_id.present?
      "http://www.facebook.com/profile.php?id=#{gamer_profile.facebook_id}"
    else
      "https://secure.gravatar.com/#{generate_gravatar_hash}"
    end
  end

  def get_avatar_url
    if gamer_profile.present? && gamer_profile.facebook_id.present?
      "https://graph.facebook.com/#{gamer_profile.facebook_id}/picture?size=square"
    else
      "https://secure.gravatar.com/avatar/#{generate_gravatar_hash}?d=mm&s=50"
    end
  end

  def reward_click(click)
    Downloader.get_with_retry("#{API_URL}/offer_completed?click_key=#{click.key}")
  end

  private

  def generate_gravatar_hash
    Digest::MD5.hexdigest email.strip.downcase
  end

  def check_referrer
    if referrer.present? && referrer != 'tjreferrer:'
      if referrer.starts_with?('tjreferrer:')
        click = Click.new :key => referrer.gsub('tjreferrer:', '')
        if click.rewardable?
          device = Device.new :key => click.udid
          device.product = click.device_name
          device.save
          devices.build(:device => device)
          reward_click(click)
        end
      else
        begin
          invitation_id, advertiser_app_id = ObjectEncryptor.decrypt(referrer).split(',')
        rescue OpenSSL::Cipher::CipherError
        end
        if invitation_id
          invitation = Invitation.find_by_id(invitation_id) || (Invitation.find_by_id(advertiser_app_id) if advertiser_app_id)
          if invitation
            self.referred_by = invitation.gamer_id
            referred_by_gamer = Gamer.find_by_id(self.referred_by)
            if referred_by_gamer
              follow_gamer(referred_by_gamer)
              Invitation.reconcile_pending_invitations(self, :invitation => invitation)
            end
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
