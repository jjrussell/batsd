require 'spec_helper'

describe BrandOfferMapping do

  it { should belong_to :offer}
  it { should belong_to :brand}
  it { should validate_presence_of :offer}
  it { should validate_presence_of :brand}

  subject { Factory(:brand_offer_mapping) }

  it { should validate_numericality_of :allocation }

  describe '#get_new_allocation' do
    context 'before validation' do
      before :each do
        @brand_offer_mapping = BrandOfferMapping.new
        @offer = Factory(:app).primary_offer
        @brand_offer_mapping.offer = @offer
        @counter = mock()
        BrandOfferMapping.stubs(:mappings_by_offer).with(@offer).returns(@counter)
      end

      context 'when first brand for an offer' do
        it 'sets allocation to 100' do
          @counter.stubs(:count).returns(0)
          @brand_offer_mapping.send(:get_new_allocation)
          @brand_offer_mapping.allocation.should == 100
        end
      end

      context 'when second brand for an offer' do
        it 'sets allocation to 50' do
          @counter.stubs(:count).returns(1)
          @brand_offer_mapping.send(:get_new_allocation)
          @brand_offer_mapping.allocation.should == 50
        end
      end

      context 'when third brand for an offer' do
        it 'sets allocation to 33' do
          @counter.stubs(:count).returns(2)
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
        BrandOfferMapping.stubs(:mappings_by_offer).with(@offer).returns(@offer_mappings)
        @brand_offer_mapping.expects(:allocation=).never
      end

     context 'when no brand for an offer' do
        it 'will not distribute allocation to other mappings' do
          @offer_mappings.stubs(:count).returns(0)
          @offer_mappings.expects(:each).never
          @brand_offer_mapping.send(:redistribute_allocation).should be_true
        end
      end

      context 'when first brand for an offer' do
        it 'will not distribute allocation to other mappings' do
          @offer_mappings = [@brand_offer_mapping]
          @offer_mappings.stubs(:count).returns(1)
          BrandOfferMapping.stubs(:mappings_by_offer).with(@offer).returns(@offer_mappings)
          @brand_offer_mapping.send(:redistribute_allocation).should_not be_false
        end
      end

      context 'when second brand for an offer' do
        it 'will distribute allocation to the other mapping' do
          @other_brand_offer_mapping = mock()
          @other_brand_offer_mapping.stubs(:id).returns('other_test')
          @other_brand_offer_mapping.stubs(:allocation=).with(50).once
          @other_brand_offer_mapping.stubs(:save!)
          @offer_mappings = [@brand_offer_mapping, @other_brand_offer_mapping]
          @offer_mappings.stubs(:count).returns(2)
          BrandOfferMapping.stubs(:mappings_by_offer).with(@offer).returns(@offer_mappings)
          @brand_offer_mapping.send(:redistribute_allocation).should_not be_false
        end
      end

      context 'when third brand for an offer' do
        it 'will distribute allocation to other mappings roughly evenly' do
          @other_brand_offer_mapping = mock()
          @other_brand_offer_mapping.stubs(:id).returns('other_test')
          @other_brand_offer_mapping.expects(:allocation=).with(34).once
          @other_brand_offer_mapping.stubs(:save!)
          @another_brand_offer_mapping = mock()
          @another_brand_offer_mapping.stubs(:id).returns('other_test')
          @another_brand_offer_mapping.expects(:allocation=).with(33).once
          @another_brand_offer_mapping.stubs(:save!)
          @offer_mappings = [@brand_offer_mapping, @other_brand_offer_mapping, @another_brand_offer_mapping]
          @offer_mappings.stubs(:count).returns(3)
          BrandOfferMapping.stubs(:mappings_by_offer).with(@offer).returns(@offer_mappings)
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
          BrandOfferMapping.stubs(:mappings_by_offer).with(@offer).returns(@offer_mappings)
          BrandOfferMapping.any_instance.stubs(:save!).returns(nil)
          @brand_offer_mapping.send(:redistribute_allocation)
          @offer_mappings.inject(0) { |sum, x| sum + (x.allocation||0) }.should == 100
        end
      end
    end
  end
end
