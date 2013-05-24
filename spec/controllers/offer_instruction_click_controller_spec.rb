require 'spec_helper'

describe OfferInstructionClickController do
  describe '#index' do
    context 'invalid params' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(false)
      end

      it 'responds with 400' do
        get(:index)
        should respond_with(400)
      end
    end

    context 'make request' do
      before :each do
        ApplicationController.stub(:verify_params).and_return(true)
        ApplicationController.stub(:verify_records).and_return(true)
        @click = FactoryGirl.create(:click)
        Click.stub(:find).and_return(@click)
        @offer = @click.offer
        currency = @click.currency
        Currency.stub(:find_in_cache).and_return(currency)
        @params = {
          :data                  => ObjectEncryptor.encrypt(:data => 'some_data'),
          :id                    => @offer.id,
          :udid                  => @click.udid,
          :publisher_app_id      => @click.currency.app.id,
          :click_key             => @click.key
        }
      end

      context 'invalid offer' do
        before :each do
          @offer.pay_per_click = Offer::PAY_PER_CLICK_TYPES[:non_ppc]
          Offer.stub(:find_in_cache).and_return(@offer)
        end

        it 'responds with 403' do
          get(:index, @params)
          should respond_with(403)
        end

        it 'assigns @destination_url' do
          get(:index, @params)
          assigns(:destination_url).should == @request.url
        end
      end

      context 'successful request' do
        before :each do
          @now = Time.zone.parse("2012-01-01 00:00:00")
          Timecop.freeze(@now)

          @offer.pay_per_click = Offer::PAY_PER_CLICK_TYPES[:ppc_on_instruction]
          @offer.stub(:complete_action_url).and_return("some_web_url")
          Offer.stub(:find_in_cache).and_return(@offer)
          @viewed_at = @now - 10.minutes
          @params.merge!(:viewed_at => @viewed_at.to_f)
          offer_instruction_click_data = {:viewed_at => @viewed_at.to_f, :clicked_at => @now.to_f}
          @message = {:click_key => @click.key, :offer_instruction_click => offer_instruction_click_data}.to_json
        end

        after :each do
          Timecop.return
        end

        it "queues for conversion tracking" do
          Sqs.should_receive(:send_message).with(QueueNames::CONVERSION_TRACKING, @message)
          get(:index, @params)
        end

        it "should redirect to offer url" do
          get(:index, @params)
          response.should redirect_to("some_web_url")
        end
      end
    end
  end
end
