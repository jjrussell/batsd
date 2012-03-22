class ApprovableSources
  def self.available_owners
    User.account_managers
  end

  def self.option_for_owner(owner)
    [owner.email, owner.id]
  end
end
