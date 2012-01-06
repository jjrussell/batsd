class Tools::OffersController < WebsiteController
  layout 'tabbed'

  current_tab :tools
  filter_access_to :all

  before_filter :setup, :except => :creative

  def creative
    @creatives = []

    offers = if params[:offer_id]
                [Offer.find params[:offer_id]]
              else
                Offer.creative_approval_needed
              end

    offers.each do |offer|
      offer.approvals.each do |approval|
        width, height = approval.size.split 'x'
        @creatives << {
          :offer => offer,
          :preview_url => offer.display_ad_image_url(App::PREVIEW_PUBLISHER_APP_ID, width, height, nil, nil, true, false),
          :approval_url => approve_creative_tools_offers_path(:approval_id => approval.id),
          :rejection_url => reject_creative_tools_offers_path(:approval_id => approval.id)
        }
      end
    end
  end

  def approve_creative
    if success = @approval.approve!
      creative_email(:approved)
      @approval.destroy
    end

    render :json => {:success => success}
  end

  def reject_creative
    if success = @approval.reject!
      creative_email(:rejected)
      @approval.destroy
    end

    render :json => {:success => success}
  end

  private
  def setup
    @approval = CreativeApprovalQueue.find_by_id(params[:approval_id])
  end

  def creative_email(status)
    offer = @approval.offer
    app = App.find(offer.item_id)
    offer_link = edit_app_offer_url(:id => offer.id, :app_id => app.id)
    TapjoyMailer.send("deliver_offer_creative_#{status}", @approval.user.email, offer, @approval.size, offer_link)
  end
end

