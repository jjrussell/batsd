require 'spec_helper'

describe UserEvent do

  before(:each) do
    @app = FactoryGirl.create(:app)
    @device = FactoryGirl.create(:device)
    @app.cache
    # Use an IAP event, since it's got additional required params
    @geoip_data = {
      :country => "USA",
      :primary_country => "USA",
    }
    @ip_address = '10.0.0.1'
    @user_agent = 'not_a_real_user'
    @options = {
      :event_type_id => 1,
      :app_id => @app.id,
      :udid => @device.id,
      :quantity => FactoryGirl.generate(:integer),
      :price => FactoryGirl.generate(:integer).to_f,
      :name => FactoryGirl.generate(:name),
      :currency_id => "Currency #{FactoryGirl.generate(:name)}",
      :verifier => 'should_recompute_me_with_each_variable_change',
    }
    @event = UserEvent.new()
  end

  describe '#put_values' do

    context 'without a verifier' do
      before(:each) do
        @options.delete(:verifier)
      end

      it 'raises an error' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent)}.to raise_error(Exception, I18n.t('user_event.error.no_verifier'))
      end
    end

    context 'with an invalid event_type_id' do
      before(:each) do
        @options[:event_type_id] = -1
      end

      it 'raises an error' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent)}.to raise_error(Exception, "#{@options[:event_type_id]} is not a valid 'event_type_id'.")
      end
    end

    context 'with an invalid app_id' do
      before(:each) do
        @options[:app_id] = "completely f'd app_id"
      end

      it 'raises an error' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent)}.to raise_error(Exception, "App ID '#{@options[:app_id]}' could not be found. Check 'app_id' and try again.")
      end
    end

    context 'without any device identifiers' do
      before(:each) do
        @options.delete(:udid)
      end

      it 'raises an error saying that the no device identifier could be found' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent)}.to raise_error(Exception, I18n.t('user_event.error.no_device'))
      end
    end

    context 'with at least one missing option' do
      before(:each) do
        #randomly decided to remove quantity here, any param with its associated error message (below) should work
        @options.delete(:quantity)
      end

      it 'raises an error' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent)}.to raise_error(Exception, "Expected attribute 'quantity' of type 'int' not found.")
      end
    end

    context 'with an option of the wrong data type' do
      before(:each) do
        @options[:price] = 'invalid price123'
      end

      it 'raises an error' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent)}.to raise_error(Exception, "Error assigning 'price' attribute. The value 'invalid price123' is not of type 'float'.")
      end
    end

    context 'with an invalid verifier' do
      it 'raises an error saying that the verifier is invalid' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent)}.to raise_error(Exception, I18n.t('user_event.error.verification_failed'))
      end
    end

    context 'with a valid verifier' do
      before(:each) do
        @options[:verifier] = Digest::SHA256.hexdigest("#{@app.id}:#{@device.id}:#{@app.secret_key}:#{@options[:event_type_id]}")
      end

      it 'successfully creates and can save a UserEvent' do
        expect{@event.put_values(@options, @ip_address, @geoip_data, @user_agent) and @event.save}.to_not raise_error
      end
    end
  end
end
