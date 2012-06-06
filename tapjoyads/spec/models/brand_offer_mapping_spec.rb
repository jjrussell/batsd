require 'spec_helper'

describe BrandOfferMapping do

  subject { Factory(:brand_offer_mapping) }

  it { should belong_to :offer }
  it { should belong_to :brand }
  it { should validate_presence_of :offer }
  it { should validate_presence_of :brand }
  it { should validate_numericality_of :allocation }
  it { should validate_uniqueness_of(:offer_id).scoped_to(:brand_id) }

  describe '#get_new_allocation' do
    context 'before validation' do
      before :each do
        @brand_offer_mapping = BrandOfferMapping.new
        @offer = Factory(:app).primary_offer
        @brand_offer_mapping.offer = @offer
        @counter = mock()
        BrandOfferMapping.stub(:mappings_by_offer).with(@offer).and_return(@counter)
      end

      context 'when first brand for an offer' do
        it 'sets allocation to 100' do
          @counter.stub(:count).and_return(0)
          @brand_offer_mapping.send(:get_new_allocation)
          @brand_offer_mapping.allocation.should == 100
        end
      end

      context 'when second brand for an offer' do
        it 'sets allocation to 50' do
          @counter.stub(:count).and_return(1)
          @brand_offer_mapping.send(:get_new_allocation)
          @brand_offer_mapping.allocation.should == 50
        end
      end

      context 'when third brand for an offer' do
        it 'sets allocation to 33' do
          @counter.stub(:count).and_return(2)
          @brand_offer_mapping.send(:get_new_allocation)
          @brand_offer_mapping.allocation.should == 33
        end
      end
    end
  end

  describe '#redistribute_allocation' do
    context 'after commit' do
      before :each do
        @brand_offer_mapping = BrandOfferMapping.new
        @offer = Factory(:app).primary_offer
        @brand_offer_mapping.offer = @offer
        @brand_offer_mapping.id = 'test'
        @offer_mappings = mock()
        BrandOfferMapping.stub(:mappings_by_offer).with(@offer).and_return(@offer_mappings)
        @brand_offer_mapping.should_receive(:allocation=).never
      end

     context 'when no brand for an offer' do
        it 'will not distribute allocation to other mappings' do
          @offer_mappings.stub(:count).and_return(0)
          @offer_mappings.should_receive(:each).never
          @brand_offer_mapping.send(:redistribute_allocation).should be_true
        end
      end

      context 'when first brand for an offer' do
        it 'will not distribute allocation to other mappings' do
          @offer_mappings = [@brand_offer_mapping]
          @offer_mappings.stub(:count).and_return(1)
          BrandOfferMapping.stub(:mappings_by_offer).with(@offer).and_return(@offer_mappings)
          @brand_offer_mapping.send(:redistribute_allocation).should_not be_false
        end
      end

      context 'when second brand for an offer' do
        it 'will distribute allocation to the other mapping' do
          @other_brand_offer_mapping = mock()
          @other_brand_offer_mapping.stub(:id).and_return('other_test')
          @other_brand_offer_mapping.stub(:allocation=).with(50).once
          @other_brand_offer_mapping.stub(:save!)
          @offer_mappings = [@brand_offer_mapping, @other_brand_offer_mapping]
          @offer_mappings.stub(:count).and_return(2)
          BrandOfferMapping.stub(:mappings_by_offer).with(@offer).and_return(@offer_mappings)
          @brand_offer_mapping.send(:redistribute_allocation).should_not be_false
        end
      end

      context 'when third brand for an offer' do
        it 'will distribute allocation to other mappings roughly evenly' do
          @other_brand_offer_mapping = mock()
          @other_brand_offer_mapping.stub(:id).and_return('other_test')
          @other_brand_offer_mapping.should_receive(:allocation=).with(34).once
          @other_brand_offer_mapping.stub(:save!)
          @another_brand_offer_mapping = mock()
          @another_brand_offer_mapping.stub(:id).and_return('other_test')
          @another_brand_offer_mapping.should_receive(:allocation=).with(33).once
          @another_brand_offer_mapping.stub(:save!)
          @offer_mappings = [@brand_offer_mapping, @other_brand_offer_mapping, @another_brand_offer_mapping]
          @offer_mappings.stub(:count).and_return(3)
          BrandOfferMapping.stub(:mappings_by_offer).with(@offer).and_return(@offer_mappings)
          @brand_offer_mapping.send(:redistribute_allocation).should_not be_false
        end
      end

      context 'when there are six brands for an offer' do
        it 'will have an allocation sum equal to 100' do
          @brand_offer_mapping = BrandOfferMapping.new
          @brand_offer_mapping.offer = @offer
          @brand_offer_mapping.id = 'test'
          @other1 = @brand_offer_mapping.clone
          @other2 = @other1.clone
          @other3 = @other2.clone
          @other4 = @other3.clone
          @other5 = @other4.clone
          @brand_offer_mapping.allocation = 16
          @offer_mappings = [@brand_offer_mapping, @other1, @other2, @other3, @other4, @other5]
          BrandOfferMapping.stub(:mappings_by_offer).with(@offer).and_return(@offer_mappings)
          BrandOfferMapping.any_instance.stub(:save!).and_return(nil)
          @brand_offer_mapping.send(:redistribute_allocation)
          @offer_mappings.inject(0) { |sum, x| sum + x.allocation }.should == 100
        end
      end
    end
  end
end
