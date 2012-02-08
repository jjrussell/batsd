class SearchController < WebsiteController

  filter_access_to :all

  def offers
    if params[:app_offers_only]
      conditions = [ "name LIKE ? AND item_type = ?", "%#{params[:term]}%", 'app' ]
    else
      conditions = [ "name LIKE ?", "%#{params[:term]}%" ]
    end

    results = Offer.find(:all,
      :conditions => conditions,
      :order => 'hidden ASC, active DESC, name ASC',
      :limit => 10
    ).collect do |o|
      if params[:more_details]
        result = { :label => o.search_result_name, :id => o.id, :user_enabled => o.user_enabled, :name => o.name, :description => "", :click_url => "", :icon_url => o.get_icon_url }
        if o.item_type == "App"
          app = App.find_by_id(o.item_id)
          result[:description] = app.description
          result[:click_url]   = Linkshare.add_params(app.info_url)
        end
        result
      else
        { :label => o.search_result_name, :url => statz_path(o), :id => o.id, :user_enabled => o.user_enabled, :daily_budget => o.daily_budget, :bid => o.bid, :payment => o.payment}
      end
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
    term = params[:term].to_s.strip

    if term =~ UUID_REGEX
      conditions = [ "id = ?", "#{term}" ]
      results = Partner.find(:all,
        :conditions => conditions,
        :include => ['offers', 'users'],
        :limit => 1
      )
    end

    if results.blank?
      term = "#{term}%"
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

  def gamers
    conditions = [ "email LIKE ?", "#{params[:term]}%" ]
    @gamers = Gamer.find(:all,
      :conditions => conditions,
      :order => 'email ASC',
      :limit => 100
    )

    render :partial => 'gamers'
  end
end
