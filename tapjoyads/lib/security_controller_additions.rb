module SecurityControllerAdditions
  def self.included(base)
    base.helper_method :may?, :may_not?
  end

  def may?(*args)
    can?(*args)
  end

  def may_not?(*args)
    cannot?(*args)
  end

  class GrantAllAbility
    include CanCan::Ability

    def initialize(user)
      can :access, :all
    end
  end
end
