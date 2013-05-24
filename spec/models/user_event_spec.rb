require 'spec_helper'

describe UserEvent do

  before(:each) do
    @iap_data = {
      :quantity       => FactoryGirl.generate(:integer),
      :price          => FactoryGirl.generate(:integer).to_f,
      :name           => "Item #{FactoryGirl.generate(:name)}",
      :currency_code  => "Currency #{FactoryGirl.generate(:name)}",
      :item_id        => FactoryGirl.generate(:guid),
#      :verifier       => 'should_recompute_me_with_each_variable_change_when_verifier_enabled',
    }
  end

  describe '#new' do

    context 'with an invalid event_type_id' do
      it 'raises an invalid event type error' do
        expect{UserEvent.new(:invalid)}.to raise_error(UserEvent::UserEventInvalid, I18n.t('user_event.error.invalid_event_type'))
      end
    end

    context 'when required fields are missing' do
      context 'and the missing field has no alternatives' do
        before(:each) do
          @iap_data.delete(:quantity)
          @error_msg = I18n.t('user_event.error.missing_fields', { :missing_fields_string => "quantity" })
        end

        it 'raises a missing fields error' do
          expect{UserEvent.new(:iap, @iap_data)}.to raise_error(UserEvent::UserEventInvalid, @error_msg)
        end
      end

      context 'and the missing field has alternatives' do
        before(:each) do
          @iap_data.delete(:name)
        end

        context 'and those alternatives are missing' do
          before(:each) do
            @iap_data.delete(:item_id)
          @error_msg = I18n.t('user_event.error.missing_fields', { :missing_fields_string => "name, item_id" })
          end

          it 'raises a missing fields error' do
            expect{UserEvent.new(:iap, @iap_data)}.to raise_error(UserEvent::UserEventInvalid, @error_msg)
          end
        end

        context 'and an alternative is present' do
          it 'succeeds' do
            expect{UserEvent.new(:iap, @iap_data)}.to_not raise_error
          end
        end
      end
    end

    context 'with a field of the wrong data type' do
      before(:each) do
        @iap_data[:price] = 'invalid price123'
        @error_msg = I18n.t('user_event.error.invalid_field', { :field => :price, :type => UserEvent::EVENT_TYPE_MAP[:iap][:price] })
      end

      it 'raises an invalid field error' do
        expect{UserEvent.new(:iap, @iap_data)}.to raise_error(UserEvent::UserEventInvalid, @error_msg)
      end
    end

    context 'with fields not defined in that event\'s mapping' do
      before(:each) do
        @iap_data[:time] = FactoryGirl.generate(:integer)
        @error_msg = I18n.t('user_event.error.undefined_fields', { :undefined_fields_string => 'time' })
      end

      it 'raises an undefined fields error' do
        expect{UserEvent.new(:iap, @iap_data)}.to raise_error(UserEvent::UserEventInvalid, @error_msg)
      end
    end
  end
end
