require 'spec_helper'

describe UserEventsController do

  let(:app) { Factory(:app) }
  let(:device) { Factory(:device) }

  before(:each) do
    Device.stub(:find).and_return(device)
  end

  describe '#create' do
    context 'with invalid params' do

      context 'with an invalid app_id' do

        before(:each) do
          @params = {
            :app_id         => "invalid_app_id",
            :udid           => device.key,
            :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
          }
        end

        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == 400
          response.body.should    start_with "Could not find app or device"
        end
      end

      context 'with an invalid event_type_id' do

        before(:each) do
          @params = {
            :app_id         => app.id,
            :udid           => device.key,
            :event_type_id  => "invalid_event_type_id",
          }
        end

        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == 400
          response.body.should    start_with "Could not find app or device."
        end
      end
    end

    context 'with valid params' do

      context 'with a device has never run this app before' do

        before(:each) do
          @params = {
            :app_id         => app.id,
            :udid           => device.key,
            :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
          }
        end

        it 'renders the ERROR_PARAMS message' do
          post(:create, @params)
          response.status.should  == 400
          response.body.should    start_with "Could not find app or device."
        end
      end

      context 'with a device that has run this app before' do

        before(:each) do
          device.set_last_run_time!(app.id)
          @params = {
            :app_id         => app.id,
            :udid           => device.key,
            :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:SHUTDOWN),
          }
        end

        it 'renders SUCCESS_MESSAGE' do
          post(:create, @params)
          response.status.should  == 200
          response.body.should    == "Successfully saved user event."
        end
      end

      # TODO: Scrap the following tests when custom events are added

      context 'with an IAP event' do

        context 'without data' do

          before(:each) do
            device.set_last_run_time!(app.id)
            @params = {
              :app_id         => app.id,
              :udid           => device.key,
              :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:IAP),
            }
          end

          it 'renders ERROR_EVENT' do
            post(:create, @params)
            response.status.should  == 400
            response.body.should    start_with "Error parsing the event info."
          end
        end

        context 'with valid data' do

          before(:each) do
            device.set_last_run_time!(app.id)
            @params = {
              :app_id         => app.id,
              :udid           => device.key,
              :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:IAP),
              :data           => {
                :name   => Factory.next(:name),
                :price  => Factory.next(:integer),
              },
            }
          end

          it 'renders SUCCESS_MESSAGE' do
            post(:create, @params)
            response.status.should  == 200
            response.body.should    == "Successfully saved user event."
          end
        end

        context 'with invalid data' do

          before(:each) do
            device.set_last_run_time!(app.id)
            @params = {
              :app_id         => app.id,
              :udid           => device.key,
              :event_type_id  => UserEvent::EVENT_TYPE_IDS.index(:IAP),
              :data           => {
                :name   => Factory.next(:name),
                :price  => "invalid_price!@!@",
              },
            }
          end

          it 'renders ERROR_EVENT' do
            post(:create, @params)
            response.status.should  == 400
            response.body.should    start_with "Error parsing the event info."
          end
        end
      end

    end
  end
end
