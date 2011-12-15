class Invitation < ActiveRecord::Base
  include UuidPrimaryKey

  EMAIL    = 0
  FACEBOOK = 1

  CHANNEL = {
    EMAIL    => 'email',
    FACEBOOK => 'facebook',
  }

  PENDING  = 0
  ACCEPTED = 1
  CLOSED   = 2

  STATUS = {
    PENDING  => 'pending',
    ACCEPTED => 'accepted',
    CLOSED   => 'closed',
  }

  belongs_to :gamer
  has_one :noob, :as => :gamer

  validates_presence_of  :gamer, :channel
  validates_presence_of  :external_info
  validates_inclusion_of :channel, :in => CHANNEL.keys
  validates_inclusion_of :status, :in => STATUS.keys

  named_scope :email,    :conditions => { :channel => EMAIL }
  named_scope :facebook, :conditions => { :channel => FACEBOOK }
  named_scope :pending_invitations_for, lambda { |external_info| { :conditions => ["external_info = ? and status = ?", external_info, PENDING ] } }
  named_scope :for_gamer, lambda { |gamer| { :conditions => ['gamer_id = ?', gamer.id] } }

  def self.invitation_message(name)
    <<-eos.gsub(/^ {6}/, '')
      #{name} has invited you to join Tapjoy, the BEST place to find the hottest new apps. Signing up is free and you'll be able discover the best apps on iOS and Android, while also earning currency in your favorite apps.

      No need to wade through thousands of apps in the App Store or the Android Market to find your next download. Tapjoy has you covered and recommends apps we know you'll like.

      To get started, create your account here:
    eos
  end

  def pending?; status == PENDING; end

  def self.reconcile_pending_invitations(noob, options={})
    external_info = options.delete(:external_info)  { nil }
    invitation    = options.delete(:invitation)     { nil }
    if invitation
      external_info = noob.external_info(invitation.channel)
    elsif external_info && noob
      invitation = Invitation.find_by_gamer_id_and_external_info(noob.referred_by, external_info)
    else
      raise "Need invitation or external info"
    end
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    Invitation.pending_invitations_for(external_info).each do |invitation|
      gamer = Gamer.find_by_id(invitation.gamer_id)
      gamer.follow_gamer(noob) if gamer
    end

    if invitation && invitation.external_info == external_info
      invitation.status = ACCEPTED
      invitation.noob_id = noob.id
      invitation.save
    end

    Invitation.pending_invitations_for(external_info).each do |invitation|
      invitation.status = CLOSED
      invitation.noob_id = noob.id
      invitation.save
    end
  end

  def encrypted_referral_id
    ObjectEncryptor.encrypt("#{gamer.id},#{id}")
  end
end
