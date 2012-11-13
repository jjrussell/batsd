module SecurityControllerAdditions
  def self.included(base)
    base.helper_method :may?, :may_not?
  end

  # TODO: backport of CanCan method signature from 2.0 branch
  # attribute argument will be backported in a different commit
  def may?(action, subject, attribute = nil)
    can?(action, subject)
  end

  def may_not?(*args)
    cannot?(*args)
  end

  class GrantAllAbility
    include CanCan::Ability

    def initialize(user)
      can :manage, :all
    end
  end
end
