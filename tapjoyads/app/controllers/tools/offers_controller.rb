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
      next unless offer.item_type == 'App' # For now we only care about app offers

      offer.approvals.each do |approval|
        width, height = approval.size.split 'x'

        preview_url = if offer.featured?
                        preview_app_offer_path(:id => offer.id, :app_id => offer.item_id, :image_size => approval.size, :preview => true, :only_one => true)
                      else
                        offer.preview_display_ad_image_url(App::PREVIEW_PUBLISHER_APP_ID, width, height)
                      end

        @creatives << {
          :offer => offer,
          :size => approval.size,
          :preview_url => preview_url,
          :approval_url => approve_creative_tools_offers_path(:approval_id => approval.id),
          :rejection_url => reject_creative_tools_offers_path(:approval_id => approval.id)
        }
      end
    end
  end

  def approve_creative
    creative_email(:approved) if success = @approval.approve!

    render :json => {:success => success}
  end

  def reject_creative
    creative_email(:rejected) if success = @approval.reject!

    render :json => {:success => success}
  end

  private
  def setup
    @approval = CreativeApprovalQueue.find_by_id(params[:approval_id])
    raise "Offer is not associated with any app, will not handle creatives" unless @approval.offer.item_type == 'App'
  end

  def creative_email(status)
    offer = @approval.offer
    offer_link = edit_app_offer_url(:id => offer.id, :app_id => offer.item_id)
    TapjoyMailer.send("deliver_offer_creative_#{status}", @approval.user.email, offer, @approval.size, offer_link)
  end
end

