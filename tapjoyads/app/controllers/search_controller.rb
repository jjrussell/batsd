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
      conditions = [ "(email LIKE ? OR email like ?) AND email NOT LIKE ?",
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
end
