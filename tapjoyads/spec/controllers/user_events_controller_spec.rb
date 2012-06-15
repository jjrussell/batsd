require 'spec_helper'

describe UserEventsController do

  let(:app) { FactoryGirl.create(:app) }
  let(:device) { FactoryGirl.create(:device) }

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

        it 'fails with the ERROR_APP_ID_OR_UDID_MSG message' do
          post(:create, @params)
          response.status.should == 412
          response.body.should == UserEvent::ERROR_APP_ID_OR_UDID_MSG
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

        it 'fails with the ERROR_APP_ID_OR_UDID_MSG message' do
          post(:create, @params)
          response.status.should == 412
          response.body.should == UserEvent::ERROR_APP_ID_OR_UDID_MSG 
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

        it 'succeeds and returns the SUCCESS_MSG message' do
          post(:create, @params)
          response.status.should == 201
          response.body.should == UserEvent::SUCCESS_MSG
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

        it 'succeeds and returns the SUCCESS_MSG message' do
          post(:create, @params)
          response.status.should == 201
          response.body.should == UserEvent::SUCCESS_MSG
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

        it 'fails with the ERROR_EVENT_INFO_MSG message' do
            post(:create, @params)
          response.status.should == 406
          response.body.should == UserEvent::ERROR_EVENT_INFO_MSG
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
                :name   => FactoryGirl.generate(:name),
                :price  => FactoryGirl.generate(:integer),
              },
            }
          end

          it 'succeeds and returns the SUCCESS_MSG message' do
            post(:create, @params)
            response.status.should == 201
            response.body.should == UserEvent::SUCCESS_MSG
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
                :name   => FactoryGirl.generate(:name),
                :price  => "invalid_price!@!@",
              },
            }
          end

          it 'fails with the ERROR_EVENT_INFO_MSG message' do
            post(:create, @params)
            response.status.should == 406
            response.body.should == UserEvent::ERROR_EVENT_INFO_MSG
          end
        end
      end

    end
  end
end
