class Sales::CreateAccountController < Sales::SalesController
  
  def index
    
  end

  def confirm
    unless verify_params([:sales_person_id, :email, :company_name, :contact_name,
        :contact_phone, :free_credits], 
        {:allow_empty => false, :render_missing_text => false})
      flash[:error] = "Cannot leave any fields blank"
      render 'index'
      return
    end
  end
  
  def create
    free_credits_in_cents = params[:free_credits].to_i * 100
    
    url = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com' +
        '/Service1.asmx/CreateAccount?sales_password=uew862nvm01ds' +
        "&email=#{CGI::escape(params[:email])}" +
        "&sales_person_id=#{CGI::escape(params[:sales_person_id])}" +
        "&company_name=#{CGI::escape(params[:company_name])}" +
        "&contact_name=#{CGI::escape(params[:contact_name])}" +
        "&contact_email=#{CGI::escape(params[:email])}" +
        "&contact_phone=#{CGI::escape(params[:contact_phone])}" +
        "&free_credits_in_cents=#{free_credits_in_cents}"
    
    response = Downloader.get(url, :timeout => 30)
    if response =~ />OK<\/string>/
      flash[:info] = "Successfully created account for #{params[:email]}"
    else
      flash[:error] = response
    end
    
    redirect_to "/sales/create_account?sales_person_id=#{params[:sales_person_id]}"
  end

end