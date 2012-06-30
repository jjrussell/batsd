require 'spec_helper'

describe UserEvent do

  let(:app) { FactoryGirl.create(:app)}
  let(:device) { FactoryGirl.create(:device) }

  before(:each) do
    Device.stub(:find).and_return(device)
    app.cache
    # Use an IAP event, since it's got additional required params
    @options = {
      :event_type_id => 1,
      :app_id => app.id,
      :udid => device.id,
      :quantity => 2,
      :price => 34.50,
      :name => 'BFG',
      :currency_id => 'USD',
    }
    string_to_be_verified = @options.sort.map { |key, val| "#{val}" }.join(':')
    @options[:verifier] = Digest::SHA1.digest(app.secret_key + string_to_be_verified)
  end

  describe '#initialize' do
    context 'without a verifier' do
      it 'raises an error' do
        expect{UserEvent.new()}.to raise_error(Exception, I18n.t('user_event.error.no_verifier'))
      end
    end

    context 'with an invalid verifier' do
      before(:each) do
        @options[:verifier] = 'not a valid verifier'
      end

      context 'with an invalid event_type_id' do
        it 'raises an error' do
          @options[:event_type_id] = -1
          expect{UserEvent.new(@options)}.to raise_error(Exception, "#{@options[:event_type_id]} is not a valid 'event_type_id'.")
        end
      end

      context 'with a valid event_type_id' do
        context 'with missing params' do
          before(:each) do
            #randomly decided to remove quantity here, any param with its associated error message (below) should work
            @options.delete(:quantity)
          end

          it 'raises an error' do
            expect{UserEvent.new(@options)}.to raise_error(Exception, "Expected attribute 'quantity' of type 'int' not found.")
          end
        end

        context 'with no missing params' do
          context 'with an invalid app_id' do
            before(:each) do
              @options[:app_id] = "completely f'd app_id"
            end

            it 'raises an error' do
              expect{UserEvent.new(@options)}.to raise_error(Exception, "App ID #{@options[:app_id]} could not be found. Check 'app_id' and try again.")
            end
          end

          context 'with a valid app_id' do
            it 'raises an error saying that the verifier is invalid' do
              expect{UserEvent.new(@options)}.to raise_error(Exception, I18n.t('user_event.error.verification_failed'))
            end
          end
        end
      end
    end

    context 'with a valid verifier' do
      before(:each) do
        @options.delete(:verifier) if @options.has_key?(:verifier)
      end

      context 'with an invalid event_type_id' do
        before(:each) do
          @options[:event_type_id] = -1
          string_to_be_verified = @options.sort.map { |key, val| "#{val}" }.join(':')
          @options[:verifier] = Digest::SHA256.digest(app.secret_key + string_to_be_verified)
        end

        it 'raises an error' do
          expect{UserEvent.new(@options)}.to raise_error(Exception, "#{@options[:event_type_id]} is not a valid 'event_type_id'.")
        end
      end

      context 'with a valid event_type_id' do
        context 'with missing params' do
          before(:each) do
            #randomly decided to remove quantity here, any param with its associated error message (below) should work
            @options.delete(:quantity)
            string_to_be_verified = @options.sort.map { |key, val| "#{val}" }.join(':')
            @options[:verifier] = Digest::SHA1.digest(app.secret_key + string_to_be_verified)
          end

          it 'raises an error' do
            expect{UserEvent.new(@options)}.to raise_error(Exception, "Expected attribute 'quantity' of type 'int' not found.")
          end
        end

        context 'with no missing params' do
          context 'with an invalid app_id' do
            before(:each) do
              @options[:app_id] = "completely f'd app_id"
              string_to_be_verified = @options.sort.map { |key, val| "#{val}" }.join(':')
              @options[:verifier] = Digest::SHA1.digest(app.secret_key + string_to_be_verified)
            end

            it 'raises an error' do
              expect{UserEvent.new(@options)}.to raise_error(Exception, "App ID #{@options[:app_id]} could not be found. Check 'app_id' and try again.")
            end
          end

          context 'with a valid app_id' do
            context 'with a param of the wrong data type' do
              before(:each) do
                @options[:price] = "not a valid price"
                string_to_be_verified = @options.sort.map { |key, val| "#{val}" }.join(':')
                @options[:verifier] = Digest::SHA1.digest(app.secret_key + string_to_be_verified)
              end

              it 'raises an error' do
                expect{UserEvent.new(@options)}.to raise_error(Exception, "Error assigning 'price' attribute. The value 'not a valid price' is not of type 'float'.")
              end
            end

            context 'with all params of valid types' do
              before(:each) do
                string_to_be_verified = @options.sort.map { |key, val| "#{val}" }.join(':')
                @options[:verifier] = Digest::SHA256.digest(app.secret_key + string_to_be_verified)
              end

              it 'returns a UserEvent object, which can be saved' do
                expect{UserEvent.new(@options).save}.to_not raise_error
              end
            end
          end
        end
      end
    end
  end
end
