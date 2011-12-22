class Tools::OffersController < WebsiteController
  layout 'tabbed'

  current_tab :tools
  filter_access_to :all

  def creative
    @creatives = []

    offers = if params[:offer_id]
                [Offer.find params[:offer_id]]
              else
                Offer.creative_approval_needed
              end

    offers.each do |offer|
      offer.banner_creatives.each do |size|
        next if offer.banner_creative_approved?(size)
        width, height = size.split 'x'
        @creatives << {
          :offer => offer,
          :preview_url => offer.display_ad_image_url(publisher_app_id = App::PREVIEW_PUBLISHER_APP_ID, width, height, nil, nil, true, false),
          :approval_url => approve_creative_tools_offers_path(:offer_id => offer.id, :size => size),
          :rejection_url => reject_creative_tools_offers_path(:offer_id => offer.id, :size => size)
        }
      end
    end
  end

  def approve_creative
    @offer = Offer.find_by_id(params[:offer_id])
    success = false

    if @offer
      @offer.approve_banner_creative(params[:size])
      creative_email(:approved, @offer) if success = @offer.save
    end

    render :json => {:success => success}
  end

  def reject_creative
    @offer = Offer.find_by_id(params[:offer_id])
    success = false

    if @offer
      @offer.remove_banner_creative(params[:size])
      creative_email(:rejected, @offer) if success = @offer.save
    end

    render :json => {:success => success}
  end

  private
  def creative_email(status, offer)
    app = App.find(offer.item_id)
    offer_link = edit_app_offer_url(:id => offer.id, :app_id => app.id)
    TapjoyMailer.send("deliver_offer_creative_#{status}", offer.partner.contact_email, offer, params[:size], offer_link)
  end
end

