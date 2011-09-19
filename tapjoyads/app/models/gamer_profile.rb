class GamerProfile < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :gamer

  validate :at_least_age_thirteen

  def at_least_age_thirteen
    unless birthdate.nil?
      turns_thirteen = birthdate.years_since(13)
      errors.add(:birthdate, "is less than thirteen years ago") if (turns_thirteen.future?)
    end
  end
end
