# == Schema Information
#
# Table name: gamer_profiles
#
#  id                     :string(36)      not null, primary key
#  gamer_id               :string(36)      not null
#  gender                 :string(255)
#  birthdate              :date
#  city                   :string(255)
#  country                :string(255)
#  favorite_game          :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  name                   :string(255)
#  nickname               :string(255)
#  postal_code            :string(255)
#  favorite_category      :string(255)
#  use_gravatar           :boolean(1)      default(FALSE)
#  facebook_id            :string(255)
#  fb_access_token        :string(255)
#  referred_by            :string(36)
#  referral_count         :integer(4)      default(0)
#  allow_marketing_emails :boolean(1)      default(TRUE)
#

class GamerProfile < ActiveRecord::Base
  include UuidPrimaryKey

  has_one :referrer_gamer, :class_name => 'Gamer', :primary_key => :referred_by, :foreign_key => :id

  belongs_to :gamer

  validate :at_least_age_thirteen
  validates_inclusion_of :gender, :in => %w{ male female }, :allow_nil => true, :allow_blank => true
  validates_presence_of :birthdate

  delegate :blocked?, :to => :gamer
  after_save :check_suspicious_activities, :unless => :blocked?

  def at_least_age_thirteen
    unless self.birthdate.nil?
      turns_thirteen = birthdate.years_since(13)
      errors.add(:birthdate, "is less than thirteen years ago") if (turns_thirteen.future?)
    end
  end

  def city_and_country
    res = []
    res << city if city.present?
    res << country if country.present?
    res.join ", "
  end

  def city_and_country?
    city_and_country.present?
  end

  def update_facebook_info!(facebook_user)
    if facebook_id != facebook_user.id
      self.facebook_id = facebook_user.id
      self.fb_access_token = facebook_user.client.access_token
      save!

      Invitation.reconcile_pending_invitations(Gamer.find_by_id(self.gamer_id), :external_info => self.facebook_id)
    end
  end

  def dissociate_account!(account_type)
    case account_type
    when Invitation::FACEBOOK
      self.facebook_id     = nil
      self.fb_access_token = nil
    end

    save!
  end

  def too_many_referrals?
    referral_count >= Gamer::MAX_REFERRAL_THRESHOLD
  end

  private

  def check_suspicious_activities
    if too_many_referrals? && referral_count % 10 == 0
      message = {
        :gamer_id        => gamer_id,
        :behavior_type   => 'referral_count',
        :behavior_result => referral_count,
      }
      Sqs.send_message(QueueNames::SUSPICIOUS_GAMERS, message.to_json)
    end
  end
end
