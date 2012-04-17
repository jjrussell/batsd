class ApprovableSources
  def self.available_owners
    User.account_managers
  end

  def self.option_for_owner(owner)
    if Rails.configuration.cache_classes
      [owner.email, owner.id]
    else
      # This is a stop-gap for a gross issue with Rails class re-loading and
      # class references. Until a true fix is found we are just going to discard
      # any models that exhibit the issue (which would be any you've assigned since
      # the last restart).
      begin
        [owner.email, owner.id]
      rescue
        [nil, nil]
      end
    end
  end
end
