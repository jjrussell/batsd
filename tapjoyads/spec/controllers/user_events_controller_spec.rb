require 'spec/spec_helper'

describe UserEventsController do
  
  describe '#create' do
    before :each do
      @params = Factory(:user_event)
    end

    context 'with invalid params' do
    
      context 'with an invalid app_id' do
        before :each do
          @params[:app_id] = "an_invalid_app_id_!@!@!@!"
        end

        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == UserEventsController.ERROR_STATUS
          response.body.should    == UserEventsController.ERROR_PARAMS
        end
      end

      context 'with an invalid event_type_id' do
        before :each do
          @params[:event_type_id] = "X$$"
        end

        it 'renders the ERROR_EVENT message' do
          post(:create, @params)
          response.status.should  == UserEventsController.ERROR_STATUS
          response.body.should    == UserEventsController.ERROR_EVENT
        end
      end

    end

    context 'with valid params' do

      context 'with a device has never run this app before' do
        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == UserEventsController.ERROR_STATUS
          response.body.should    == UserEventsController.ERROR_PARAMS
        end
      end

      context 'with a device that has run this app before' do
        before :each do
          Device.new(:key => @params[:udid]).set_last_run_time!(@params[:app_id])
        end

        it 'renders SUCCESS_MESSAGE' do
          post(:create, @params)
          response.status.should  == UserEventsController.SUCCESS_STATUS
          response.body.should    == UserEventsController.SUCCESS_MESSAGE
        end
      end

      # TODO: Scrap the following tests when custom events are added

      context 'with a SHUTDOWN event' do
        before :each do
          @params[:event_type_id] = UserEvent.EVENT_TYPE_IDS.index(:SHUTDOWN)
          @params[:data] = "i am not blank, i am present"
        end

        it 'renders ERROR_EVENT when data is present' do
          post(:create, @params)
          response.status.should  == UserEventsController.ERROR_STATUS
          response.body.should    == UserEventsController.ERROR_EVENT
        end

      context 'with an IAP event' do
        before :each do
          @params[:event_type_id] = UserEvent.EVENT_TYPE_IDS.index(:IAP)
        end

        context 'without data' do
          it 'renders ERROR_EVENT when data is present' do
            post(:create, @params)
            response.status.should  == UserEventsController.ERROR_STATUS
            response.body.should    == UserEventsController.ERROR_EVENT
          end
        end

        context 'with valid data' do
          before :each do
            @params[:data] = {
              :name => Factory.next(:name),
              :price => Factory.next(:integer),
            }

          it 'renders SUCCESS_MESSAGE' do
            post(:create, @params)
            response.status.should  == UserEventsController.SUCCESS_STATUS
            response.body.should    == UserEventsController.SUCCESS_MESSAGE
          end
        end

        context 'with invalid data' do
          before :each do
            @params[:data] = {
              :name => Factory.next(:name),
              :price => 'invalid_integer',
            }
          end

          it 'renders SUCCESS_MESSAGE' do
            post(:create, @params)
            response.status.should  == UserEventsController.ERROR_STATUS
            response.body.should    == UserEventsController.ERROR_EVENT
          end
        end

    end

  end

end