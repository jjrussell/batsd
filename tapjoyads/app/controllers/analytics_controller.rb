class AnalyticsController < WebsiteController
  layout 'tabbed'
  filter_access_to :all

  def index
    if current_partner.apsalar_url.nil?
      @apsalar_email = get_apsalar_email
    end
  end

  def create_apsalar_account
    if params[:terms].blank?
      flash[:error] = "You must agree to the terms of use."
      redirect_to analytics_path
    else
      email = get_apsalar_email
      current_partner.apsalar_username = email.gsub(/[^a-zA-Z0-9]/, '_')[0..59]
      current_partner.apsalar_api_secret ||= UUIDTools::UUID.random_create.to_s.gsub('-','')[0..31]
      current_partner.save

      hash = {
        'f' => current_partner.name.to_s,
        'l' => '',
        'u' => current_partner.apsalar_username,
        's' => current_partner.apsalar_api_secret,
        'e' => email,
        'p' => current_partner.id
      }

      hash['h'] = Digest::MD5.hexdigest(hash['f'] + hash['l'] + hash['u'] + hash['e'] +
                            hash['s'] + hash['p'] + APSALAR_SECRET)
      array = hash.map do |k,v|
        k + '=' + CGI::escape(v)
      end

      json = JSON.load(Downloader.get(APSALAR_URL + '/api/v1/tapjoy?' + array.join('&'))) rescue {}
      if json["status"] == "ok" && ! (json["url"].blank?)
        current_partner.apsalar_url = json["url"]
        current_partner.save
        redirect_to json["url"] + '&url=/app/sdk/'
      elsif /duplicate/ =~ json["reason"]
        current_partner.apsalar_url = APSALAR_URL + "/jump.php?log=#{current_partner.apsalar_username}&sso=Tapjoy&token="
        current_partner.save
        redirect_to current_partner.apsalar_url + '&url=/app/sdk/'
      else
        # maybe send newrelic msg here?
        flash[:error] = json["reason"] + ". Please contact <a href='support@tapjoy.com'>support@tapjoy.com</a>"
        redirect_to analytics_path
      end
    end
  end

  private

  def get_apsalar_email
    if current_partner.non_managers.length == 1
      current_partner.non_managers.first.email
    elsif current_user.is_one_of?([:account_mgr, :admin])
      (current_partner.non_managers.first || current_user).email
    else
      current_user.email
    end
  end
end
