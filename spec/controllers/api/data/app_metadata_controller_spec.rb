require 'spec_helper'

describe Api::Data::AppMetadataController do
  before :each do
    @controller.stub(:verify_signature).and_return(true)
  end

  describe '#increment_or_decrement' do
    before :each do
      @app_metadata = FactoryGirl.create(:app_metadata)
      @params = {
        :id => @app_metadata.id
      }
    end

    context 'when attribute name is not provided' do
      it 'fails' do
        post(:increment_or_decrement, @params.merge(:operation_type => 'increment'))
        response.response_code.should == 422
        response.body.should include('Missing required')
      end
    end

    context 'when operation type is not provided' do
      it 'fails' do
        post(:increment_or_decrement, @params.merge(:attribute_name => 'thumbs_up'))
        response.response_code.should == 422
        response.body.should include('Missing required')
      end
    end

    context 'when no params are provided' do
      it 'fails' do
        post(:increment_or_decrement, @params)
        response.response_code.should == 422
        response.body.should include('Missing required')
      end
    end

    context 'with the correct parameters' do
      before :each do
        @params.merge!(:attribute_name => 'thumbs_up')
      end

      context 'when incrementing' do
        it 'should increment' do
          AppMetadata.any_instance.should_receive(:increment!)
          post(:increment_or_decrement, @params.merge(:operation_type => 'increment'))
        end
      end

      context 'when decrementing' do
        it 'should decrement' do
          AppMetadata.any_instance.should_receive(:decrement!)
          post(:increment_or_decrement, @params.merge(:operation_type => 'decrement'))
        end
      end
    end
  end
end
