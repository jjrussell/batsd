require 'spec_helper'

describe OfferParentIconMethods do

  subject do
    subject = Object.new
    subject.extend(OfferParentIconMethods)
    subject.stub(:id).and_return('1')
    subject
  end

  describe '#get_icon_url' do
    let(:options) { { :option1 => true, :option2 => false } }

    context 'for models with a primary_app_metadata record (aka Apps)' do
      context 'when model has a primary_app_metadata record' do
        it 'delegates to the primary_app_metadata' do
          subject.stub(:primary_app_metadata).and_return(Object.new)
          subject.primary_app_metadata.should_receive(:get_icon_url).with(options).once
        end
      end

      context 'when model does not have a primary_app_metadata record' do
        it 'calls IconHandler.get_icon_url and passes appropriate args' do
          subject.stub(:primary_app_metadata)
          IconHandler.should_receive(:get_icon_url).with(options.merge(:icon_id => IconHandler.hashed_icon_id(subject.id))).once
        end
      end
    end

    context 'for models that have an associated app' do
      before :each do
        subject.stub(:app).and_return(Object.new)
      end

      context 'when app has a primary_app_metadata record' do
        it 'delegates to the primary_app_metadata' do
          subject.app.stub(:primary_app_metadata).and_return(Object.new)
          subject.app.primary_app_metadata.should_receive(:get_icon_url).with(options).once
        end
      end

      context 'when app does not have a primary_app_metadata record' do
        it 'calls IconHandler.get_icon_url and passes appropriate args' do
          subject.app.stub(:primary_app_metadata)
          IconHandler.should_receive(:get_icon_url).with(options.merge(:icon_id => IconHandler.hashed_icon_id(subject.id))).once
        end
      end
    end

    context 'for non-app-associated models' do
      it 'calls IconHandler.get_icon_url and passes appropriate args' do
        IconHandler.should_receive(:get_icon_url).with(options.merge(:icon_id => IconHandler.hashed_icon_id(subject.id))).once
      end
    end

    after :each do
      subject.get_icon_url(options)
    end
  end

  describe '#save_icon!' do
    let(:image_data) { 'img' }

    context 'for models with a primary_app_metadata record (aka Apps)' do
      context 'when model has a primary_app_metadata record' do
        it 'delegates to the primary_app_metadata' do
          subject.stub(:primary_app_metadata).and_return(Object.new)
          subject.primary_app_metadata.should_receive(:save_icon!).with(image_data)
        end
      end

      context 'when model does not have a primary_app_metadata record' do
        it 'calls IconHandler.upload_icon! and passes appropriate args' do
          subject.stub(:primary_app_metadata)
          IconHandler.should_receive(:upload_icon!).with(image_data, subject.id, false)
        end
      end
    end

    context 'for models that have an associated app' do
      before :each do
        subject.stub(:app).and_return(Object.new)
      end

      context 'when app has a primary_app_metadata record' do
        it 'delegates to the primary_app_metadata' do
          subject.app.stub(:primary_app_metadata).and_return(Object.new)
          subject.app.primary_app_metadata.should_receive(:save_icon!).with(image_data)
        end
      end

      context 'when app does not have a primary_app_metadata record' do
        it 'calls IconHandler.upload_icon! and passes appropriate args' do
          subject.app.stub(:primary_app_metadata)
          IconHandler.should_receive(:upload_icon!).with(image_data, subject.id, false)
        end
      end
    end

    context 'for non-app-associated models' do
      context 'when .class is not VideoOffer' do
        it 'calls IconHandler.upload_icon! and passes appropriate args' do
          IconHandler.should_receive(:upload_icon!).with(image_data, subject.id, false)
        end
      end

      context 'when .class is VideoOffer' do
        it 'calls IconHandler.upload_icon! and passes appropriate args' do
          subject.stub(:class).and_return(VideoOffer)
          IconHandler.should_receive(:upload_icon!).with(image_data, subject.id, true)
        end
      end

      it "should respect child offers' 'auto_update_icon' field" do
        IconHandler.stub(:upload_icon!).and_return(true)

        offers = [Offer.new(:auto_update_icon => true), Offer.new(:auto_update_icon => false)]
        offers[0].should_receive(:remove_overridden_icon!).once
        offers[1].should_not_receive(:remove_overridden_icon!)
        subject.stub(:offers).and_return(offers)
      end
    end

    after :each do
      subject.save_icon!(image_data)
    end
  end

end
