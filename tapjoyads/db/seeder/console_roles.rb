class Seeder::ConsoleRoles < Seeder
  def self.permission(action, target)
    ConsoleSecurity::Permission.new(:action => action, :target => target)
  end

  def self.permit(name, permissions)
    p = ConsoleSecurity::SecurityPermit.find_or_create_by_name(name)
    p.permissions = permissions
    p.save!
    p
  end

  def self.role(name, permits = [])
    r = ConsoleSecurity::Role.find_or_create_by_name(name, :publicly_visible => true)
    r.security_permits = permits
    r.save!
    r
  end

  def self.run!
    # shared permission groups
    offers = permit('Offers', [
      permission(:access, "Offer"),
      permission(:access, "ActionOffer"),
      permission(:access, "DeeplinkOffer"),
      permission(:access, "GenericOffer"),
      permission(:access, "RatingOffer"),
      permission(:access, "SurveyOffer"),
      permission(:access, "VideoOffer")
    ])

    offers_ro = permit('Offers (readonly)', [
      permission(:read, "Offer"),
      permission(:read, "ActionOffer"),
      permission(:read, "DeeplinkOffer"),
      permission(:read, "GenericOffer"),
      permission(:read, "RatingOffer"),
      permission(:read, "SurveyOffer"),
      permission(:read, "VideoOffer")
    ])

    apps = permit('Apps', [
      permission(:access, "App")
    ])

    apps_ro = permit('Apps (readonly)', [
      permission(:read, "App")
    ])

    finance = permit('Finance', [
      permission(:access, "Order"),
      permission(:access, "Payout"),
      permission(:access, "PayoutInfo"),
      permission(:access, "Transfer")
    ])

    finance_ro = permit('Finance (readonly)', [
      permission(:read, "Order"),
      permission(:read, "Payout"),
      permission(:read, "PayoutInfo"),
      permission(:read, "Transfer")
    ])

    # shared roles
    role('User Manager', [
      permit('User Management', [
        permission(:access, "User"),
        permission(:access, "ConsoleSecurity::Role")
      ])
    ])

    # advertiser roles
    role('Ad Ops', [offers, apps])
    role('Advertiser - Reporting (readonly)', [offers_ro, apps_ro])
    role("Publisher's Report")
    role('Advertiser Finance Manager', [finance])
    
    # publisher roles
    role('Publisher Manager')
    role('Publisher - Reporting (readonly)')
    role('Developer')
    role('Publisher Finance Manager', [finance])
    role('Publisher Associate', [apps])

    # internal roles
    su = role('Superuser', [
      permit('Superuser', [
        permission(:access, :all)
      ])
    ])
    su.publicly_visible = false
    su.save!
  end
end
