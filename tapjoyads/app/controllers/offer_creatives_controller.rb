class OfferCreativesController < WebsiteController
  layout 'simple'

  filter_access_to :all
  before_filter :setup

  def show
    @creative_exists = @offer.has_banner_creative?(@image_size)

    @success_message = params.delete(:success_message)
    @error_message = params.delete(:error_message)
  end

  def create
    @offer.send("banner_creative_#{@image_size}_blob=", image_data)
    @offer.add_banner_creative(@image_size)

    if needs_approval = !permitted_to?(:edit, :statz)
      @offer.add_banner_approval(current_user, @image_size)
    else
      @offer.approve_banner_creative(@image_size)
    end

    @success = @offer.save
    send_approval_mail if @success && needs_approval

    return_to_form
  end

  def update
    # Apparently this was a dummy method originally... so we'll just redirect back to the form

    redirect_to_form
  end

  def destroy
    @offer.remove_banner_creative(@image_size)
    @success = @offer.save

    return_to_form
  end

  private
  def setup
    @image_size = params[:image_size]
    @label = params[:label]
    @offer = Offer.find(params[:id])

    # Okay this whole thing kind of hurts me, but we need this to work even when :app_id isn't a parameter.
    # Basically, previews must be done through apps/offers#preview right now.
    @app = if params.key?(:app_id)
             App.find(params[:app_id])
           elsif @offer.app.present?
             @offer.app
           end
    @preview_path = preview_app_offer_path(:id => @offer.id, :image_size => @image_size, :preview => true, :app_id => @app.id)

    log_activity(@offer)
  end

  def image_data
    params[:offer]["custom_creative_#{@image_size}".to_sym].read
  end

  def send_approval_mail
    approval_link = creative_tools_offers_url(:offer_id => @offer.id)
    emails = @offer.partner.account_managers.map(&:email)
    emails << 'support@tapjoy.com'
    emails.each do |mgr|
      TapjoyMailer.deliver_approve_offer_creative(mgr, @offer, @app, approval_link)
    end
  end

  def return_to_form
    redir = {
      :action => :show,
      :id => @offer.id,
      :image_size => @image_size,
      :label => @label
    }
    redir[:app_id] = @app.id if @app

    # Strict type checks in case we haven't set @success (nil is falsy, we don't want to show an error when there isn't one)
    if @success === true
      redir[:success_message] = "File #{request.method == :delete ? 'removed' : 'uploaded'} successfully."
    elsif @success === false
      redir[:error_message] = @offer.errors["custom_creative_#{@image_size}_blob".to_sym]
    end

    redirect_to redir
  end
end
