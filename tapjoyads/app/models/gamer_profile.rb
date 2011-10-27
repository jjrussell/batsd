class GamerProfile < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :gamer

  validate :at_least_age_thirteen
  validates_inclusion_of :gender, :in => %w{ male female }, :allow_nil => true, :allow_blank => true

  def at_least_age_thirteen
    unless birthdate.nil?
      turns_thirteen = birthdate.years_since(13)
      errors.add(:birthdate, "is less than thirteen years ago") if (turns_thirteen.future?)
    end
  end

  def update_facebook_info!(facebook_user)
    if facebook_id != facebook_user.id
      self.facebook_id = facebook_user.id
      self.fb_access_token = facebook_user.client.access_token
      self.image_source = 'facebook'
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
end
