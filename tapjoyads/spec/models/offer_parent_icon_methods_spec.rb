require 'spec_helper'

describe OfferParentIconMethods do

  subject do
    subject = Object.new
    subject.extend(OfferParentIconMethods)
    subject.stub(:id).and_return('1')
    subject
  end

  describe '#get_icon_url' do
    it 'calls Offer.get_icon_url and passes appropriate args' do
      options = { :option1 => true, :option2 => false }
      Offer.should_receive(:get_icon_url).with(options.merge(:icon_id => Offer.hashed_icon_id(subject.id))).once
      subject.get_icon_url(options)
    end
  end

  describe '#save_icon!' do
    let(:image_data) { 'img' }

    context 'when .class is not VideoOffer' do
      it 'calls Offer.upload_icon! and passes appropriate args' do
        Offer.should_receive(:upload_icon!).with(image_data, subject.id, false)
        subject.save_icon!(image_data)
      end
    end

    context 'when .class is VideoOffer' do
      it 'calls Offer.upload_icon! and passes appropriate args' do
        subject.stub(:class).and_return(VideoOffer)
        Offer.should_receive(:upload_icon!).with(image_data, subject.id, true)
        subject.save_icon!(image_data)
      end
    end
  end

end
