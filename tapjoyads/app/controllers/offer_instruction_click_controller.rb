class OfferInstructionClickController < ApplicationController
  prepend_before_filter :decrypt_data_param

  def index
    @offer = Offer.find_in_cache(params[:id])
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    @click = Click.find(params[:click_key], :consistent => true)
    return unless verify_records([ @currency, @offer, @click ])

    unless @offer.pay_per_click?(:ppc_on_instruction)
      @destination_url = request.url
      render 'click/unavailable_offer', :status => 403
      return
    end

    offer_instruction_click_data = {
      :viewed_at => params[:viewed_at].to_f,
      :clicked_at => Time.zone.now.to_f
    }

    click_key = @click.key
    message = { :click_key => click_key,
                :offer_instruction_click => offer_instruction_click_data }.to_json
    Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)

    complete_instruction_url = @offer.complete_action_url({
      :tapjoy_device_id      => get_device_key,
      :udid                  => params[:udid],
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => click_key,
      :itunes_link_affiliate => params[:itunes_link_affiliate],
      :library_version       => params[:library_version],
      :os_version            => params[:os_version]
    })

    redirect_to(complete_instruction_url)
  end

end
