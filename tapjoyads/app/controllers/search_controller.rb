class SearchController < WebsiteController

  filter_access_to :all

  def offers
    results = Offer.find(:all,
      :conditions => [ "name LIKE ?", "%#{params[:term]}%" ],
      :order => 'hidden ASC, name ASC',
      :limit => 10
    ).collect do |o|
      { :label => o.search_result_name, :url => statz_path(o), :id => o.id, :user_enabled => o.user_enabled, :daily_budget => o.daily_budget, :bid => o.bid, :payment => o.payment }
    end

    render(:json => results.to_json)
  end

  def users
    conditions = [ "email LIKE ?", "#{params[:term]}%" ]
    if params[:tapjoy_only] == 'true'
      tapjoy_email = "#{params[:term].split('@').first}%@tapjoy.com"
      offerpal_email = "#{params[:term].split('@').first}%@offerpal.com"
      conditions = [ "(email LIKE ? OR email LIKE ?) AND email NOT LIKE ?",
        tapjoy_email, offerpal_email, "%+%" ]
    end
    results = User.find(:all,
      :conditions => conditions,
      :order => 'email ASC',
      :limit => 30
    ).collect do |user|
      { :label => user.email, :user_id => user.id }
    end

    render(:json => results.to_json)
  end

  def partners
    conditions = [ "id = ?", "#{params[:term].to_s.strip}" ]
    results = Partner.find(:all,
      :conditions => conditions,
      :include => ['offers', 'users'],
      :limit => 1
    )

    if results.blank?
      term = "#{params[:term].to_s.strip}%"
      results = Partner.find_by_sql(
        [ 'select * from partners as p where name like ?' +
          ' order by (select count(*) from offers where partner_id = p.id) desc' +
          ' limit 20',
          term]
      )
    end

    results = results.collect do |partner|
      name    = partner.name || 'no name'
      offers  = partner.offers.count
      users   = partner.users.count
      label   = "#{name} (#{offers} offers, #{users} users)"
      { :label => label, :partner_id => partner.id, :partner_name => name }
    end

    render(:json => results.to_json)
  end
end
