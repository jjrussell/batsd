require 'spec/spec_helper'

describe UserEventsController do
  
  describe '#create' do
    context 'with invalid params' do
    
      context 'with an invalid app_id' do
        before :each do
          @device = Factory(:device)
          @params = {
            :app_id         => "invalid_app_id",
            :udid           => @device.key,
            :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
          }
        end

        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == UserEventsController::ERROR_STATUS
          response.body.should    == UserEventsController::ERROR_PARAMS
        end
      end

      context 'with an invalid event_type_id' do
        before :each do
          @app    = Factory(:app)
          @device = Factory(:device)
          @params = {
            :app_id         => @app.id,
            :udid           => @device.key,
            :event_type_id  => "invalid_event_type_id",
          }
          @device.set_last_run_time!(@app.id)
        end

        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == UserEventsController::ERROR_STATUS
          response.body.should    == UserEventsController::ERROR_PARAMS
        end
      end
    end

    context 'with valid params' do

      context 'with a device has never run this app before' do
        before :each do
          @app    = Factory(:app)
          @device = Factory(:device)
          @params = {
            :app_id         => @app.id,
            :udid           => @device.key,
            :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
          }
        end

        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == UserEventsController::ERROR_STATUS
          response.body.should    == UserEventsController::ERROR_PARAMS
        end
      end

      context 'with a device that has run this app before' do
        before :each do
          @app    = Factory(:app)
          @device = Factory(:device)
          @params = {
            :app_id         => @app.id,
            :udid           => @device.key,
            :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
          }
          @device.set_last_run_time!(@app.id)
        end

        it 'renders SUCCESS_MESSAGE' do
          post(:create, @params)
          response.status.should  == UserEventsController::SUCCESS_STATUS
          response.body.should    == UserEventsController::SUCCESS_MESSAGE
        end
      end

      # TODO: Scrap the following tests when custom events are added

      context 'with an IAP event' do

        context 'without data' do
          before :each do
            @app    = Factory(:app)
            @device = Factory(:device)
            @params = {
              :app_id         => @app.id,
              :udid           => @device.key,
              :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
            }
          end

          it 'renders ERROR_EVENT when data is present' do
            post(:create, @params)
            response.status.should  == UserEventsController::ERROR_STATUS
            response.body.should    == UserEventsController::ERROR_EVENT
          end
        end

        context 'with valid data' do
          before :each do
            @app    = Factory(:app)
            @device = Factory(:device)
            @params = {
              :app_id         => @app.id,
              :udid           => @device.key,
              :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
              :data           => {
                :name   => Factory.next(:name),
                :price  => Factory.next(:integer),
              },
            }
          end

          it 'renders SUCCESS_MESSAGE' do
            post(:create, @params)
            response.status.should  == UserEventsController::SUCCESS_STATUS
            response.body.should    == UserEventsController::SUCCESS_MESSAGE
          end
        end

        context 'with invalid data' do
          before :each do
            @app    = Factory(:app)
            @device = Factory(:device)
            @params = {
              :app_id         => @app.id,
              :udid           => @device.key,
              :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
              :data           => {
                :name   => Factory.next(:name),
                :price  => "invalid_price!@!@",
              },
            }
          end

          it 'renders ERROR_EVENT' do
            post(:create, @params)
            response.status.should  == UserEventsController::ERROR_STATUS
            response.body.should    == UserEventsController::ERROR_EVENT
          end
        end
      end

    end
  end
end