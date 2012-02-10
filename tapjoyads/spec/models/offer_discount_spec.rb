require 'spec_helper'

describe OfferDiscount do
  before :each do
    fake_the_web
  end

  context '.belongs_to' do
    it { should belong_to :partner }
  end

  context '#valid?' do
    it { should validate_presence_of :partner }
    it { should validate_presence_of :source }
    it { should validate_presence_of :expires_on }
    it { should validate_presence_of :amount }
    it { should validate_numericality_of :amount }
  end

  context 'An Admin OfferDiscount' do
    before :each do
      @app = Factory(:app)
      @offer = @app.primary_offer
      @partner = @app.partner
    end

    context 'with expires_on in the future' do
      before :each do
        @offer_discount = @partner.offer_discounts.build(:source => 'Admin', :amount => 10, :expires_on => 1.year.from_now)
      end

      it 'triggers premier_discount recalculations for its Partner when saved' do
        original_discount = @partner.premier_discount
        @offer_discount.save!
        @partner.reload
        @partner.premier_discount.should == original_discount + 10
      end

      it 'is active' do
        @offer_discount.should be_active
      end

      it 'is in the active scope' do
        @offer_discount.save!
        OfferDiscount.active.should include @offer_discount
      end

      it 'has its expires_on changed to today when deactivated' do
        @offer_discount.save!
        @offer_discount.deactivate!
        @offer_discount.expires_on.should == Time.zone.today
      end
    end

    context 'with expires_on in the past' do
      before :each do
        @offer_discount = @partner.offer_discounts.build(:source => 'Admin', :amount => 10, :expires_on => 1.year.ago)
      end

      it 'is not active' do
        @offer_discount.should_not be_active
      end

      it 'is not in the active scope' do
        @offer_discount.save!
        OfferDiscount.active.should_not include @offer_discount
      end

      it 'does nothing when deactivated' do
        @offer_discount.save!
        @offer_discount.deactivate!.should be_false
      end
    end
  end

end
