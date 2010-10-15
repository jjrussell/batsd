class OffersController < WebsiteController
  layout 'tabbed'
  current_tab :apps

  filter_access_to :all
  before_filter :find_offer
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def show
  end

  def update
    offer_params = sanitize_currency_params(params[:offer], [ :payment, :min_payment ])

    safe_attributes = [:daily_budget, :name, :payment, :user_enabled]
    if permitted_to?(:index, :statz)
      offer_params[:device_types] = offer_params[:device_types].blank? ? '[]' : offer_params[:device_types].to_json
      safe_attributes += [:tapjoy_enabled, :self_promote_only, :allow_negative_balance, :pay_per_click,
          :featured, :min_payment, :name_suffix, :ordinal, :show_rate, :min_conversion_rate, :countries,
          :cities, :postal_codes, :device_types, :publisher_app_whitelist, :overall_budget]
    end

    if @offer.safe_update_attributes(offer_params, safe_attributes)
      flash[:notice] = 'Pay-per-install was successfully updated'
      redirect_to(app_offer_path(:app_id => @app.id, :id => @offer.id))
    else
      flash[:error] = 'Update unsuccessful'
      render :action => "show"
    end
  end

  def download_udids
    bucket = S3.bucket(BucketNames::AD_UDIDS)
    data = bucket.get(Offer.s3_udids_path(@offer.id) + params[:date])
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{params[:date]}.csv")
  end

private
  def find_offer
    if permitted_to? :udids, :statz
      @app = App.find(params[:app_id], :include => [:primary_offer])
    else
      @app = current_partner.apps.find(params[:app_id], :include => [:primary_offer])
    end
    @offer = @app.primary_offer
    log_activity(@offer)
  end
end
