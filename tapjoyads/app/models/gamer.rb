class Gamer < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :gamer_devices, :dependent => :destroy
  has_many :invitations, :dependent => :destroy
  has_many :app_reviews, :as => :author, :dependent => :destroy

  has_many :review_moderation_votes
  has_many :helpful_review_votes, :class_name => 'HelpfulVote'
  has_many :bury_review_votes, :class_name => 'BuryVote'

  has_many :favorite_apps, :dependent => :destroy
  has_one :gamer_profile, :dependent => :destroy
  has_one :referrer_gamer, :class_name => 'Gamer', :primary_key => :referred_by, :foreign_key => :id

  delegate :birthdate, :birthdate?, :city, :city?, :country, :country?, :facebook_id, :facebook_id?,
           :fb_access_token, :favorite_category, :favorite_category?, :favorite_game, :favorite_game?,
           :gender, :gender?, :postal_code, :postal_code?, :referral_count,
           :referred_by, :referred_by=, :referred_by?, :to => :gamer_profile, :allow_nil => true

  validates_associated :gamer_profile, :on => :create
  validates_presence_of :email
  attr_accessor :terms_of_service
  validates_acceptance_of :terms_of_service, :on => :create, :allow_nil => false

  before_create :generate_confirmation_token
  before_create :check_referrer
  before_create :set_tos_version

  after_destroy :delete_friends

  serialize :extra_attributes, Hash

  MAX_DEVICE_THRESHOLD = 15
  MAX_REFERRAL_THRESHOLD = 50
  DAYS_BEFORE_DELETION = 3
  RUDE_BAN_LIMIT = 20

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

  def name
    @name.blank? ? email.gsub(/@.*/, '') : @name
  end

  def self.serialized_extra_attributes_accessor(*args)
    args.each do |method_name|
      eval "
        def #{method_name}
          (self.extra_attributes || {})[:#{method_name}]
        end
        def #{method_name}=(value)
          self.extra_attributes ||= {}
          self.extra_attributes[:#{method_name}] = value
        end
      "
    end
  end

  # Example Usage: list the attribute name here, then you could access it as a normal attribute
  # serialized_extra_attributes_accessor :completed_offer_count

  serialized_extra_attributes_accessor :been_buried_count
  serialized_extra_attributes_accessor :been_helpful_count

  def confirm!
    self.confirmed_at = Time.zone.now
    if save
      click = referrer_click
      reward_click(click) if click && click.rewardable?
    end
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
    when Invitation::TWITTER
      twitter_id
    end
  end

  def self.find_all_gamer_based_on_channel(channel, external)
    gamers = []

    case channel
    when Invitation::FACEBOOK
      gamers = GamerProfile.find_all_by_facebook_id(external, :include => [:gamer]).map(&:gamer)
    when Invitation::TWITTER
      gamers = Gamer.find_all_by_twitter_id(external)
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
    else
      email.sub(/@.*/,'')
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

  def get_avatar_url(size = '123')
    if gamer_profile.present? && gamer_profile.facebook_id.present?
      "https://graph.facebook.com/#{gamer_profile.facebook_id}/picture?type=normal"
    else
      "https://secure.gravatar.com/avatar/#{generate_gravatar_hash}?d=mm&s=#{size}"
    end
  end

  def all_device_data
    devices.map(&:device_data)
  end

  def reward_click(click)
    Downloader.get_with_retry("#{API_URL}/offer_completed?click_key=#{click.key}")
  end

  def update_twitter_info!(authhash)
    if twitter_id != authhash[:twitter_id]
      self.twitter_id            = authhash[:twitter_id]
      self.twitter_access_token  = authhash[:twitter_access_token]
      self.twitter_access_secret = authhash[:twitter_access_secret]
      save!

      Invitation.reconcile_pending_invitations(Gamer.find_by_id(id), :external_info => twitter_id)
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

  def require_twitter_authenticate?
    if twitter_id? and twitter_access_token? and twitter_access_secret?
      Twitter.configure do |config|
        config.consumer_key       = ENV['CONSUMER_KEY']
        config.consumer_secret    = ENV['CONSUMER_SECRET']
        config.oauth_token        = twitter_access_token
        config.oauth_token_secret = twitter_access_secret
      end
      return false
    end
    true
  end

  def encrypted_referral_id(advertiser_app_id = nil)
    ObjectEncryptor.encrypt("#{id},#{advertiser_app_id}")
  end

  def review_for(app_metadata_id)
    app_reviews.find_by_app_metadata_id(app_metadata_id)
  end

  def too_many_devices?
    gamer_devices.count >= MAX_DEVICE_THRESHOLD
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
        end
      else
        begin
          invitation_id, advertiser_app_id = ObjectEncryptor.decrypt(referrer).split(',')
        rescue OpenSSL::Cipher::CipherError
        end

        if invitation_id
          invitation = Invitation.find_by_id(invitation_id)
          invitation ||= Invitation.find_by_id(advertiser_app_id) if advertiser_app_id
          if invitation
            self.referred_by = invitation.gamer_id
            gamer = invitation.gamer
            Invitation.reconcile_pending_invitations(self, :invitation => invitation)
          else
            gamer_id = invitation_id
            gamer = Gamer.find_by_id(gamer_id)
            self.referred_by = gamer_id if gamer
          end
          follow_gamer(gamer) if gamer
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

  def referrer_click
    return nil unless referrer.present? && referrer != 'tjreferrer:' && referrer.starts_with?('tjreferrer:')
    Click.new :key => referrer.gsub('tjreferrer:', '')
  end
end
