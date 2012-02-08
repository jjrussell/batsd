require 'spec_helper'

describe OfferEvent do
  describe '.belongs_to' do
    it { should belong_to :offer }
  end

  describe '#valid?' do
    it { should validate_presence_of :scheduled_for }
    it { should validate_presence_of :offer }
  end

  context "An OfferEvent scheduled for the future" do
    before :each do
      @event = Factory(:offer_event, :scheduled_for => 1.hour.from_now)
    end

    it "is scoped as 'upcoming'" do
      OfferEvent.upcoming.should include @event
    end

    it "is not scoped as 'to_run'" do
      OfferEvent.to_run.should_not include @event
    end
  end

  context "An OfferEvent scheduled for the past" do
    before :each do
      @event = Factory(:offer_event)
      @event.scheduled_for = 1.hour.ago
      @event.save(false)
    end

    it "is scoped as 'to_run' and 'upcoming'" do
      OfferEvent.to_run.should include @event
      OfferEvent.upcoming.should include @event
    end

    context "after being run" do
      before :each do
        @event.run!
      end

      it "is no longer scoped as 'to_run' or 'upcoming'" do
        OfferEvent.to_run.should_not include @event
        OfferEvent.upcoming.should_not include @event
      end

      it "is scoped as 'completed'" do
        OfferEvent.completed.should include @event
      end
    end

    context "after being disabled" do
      before :each do
        @event.disable!
      end

      it "is no longer scoped as 'to_run' or 'upcoming'" do
        OfferEvent.to_run.should_not include @event
        OfferEvent.upcoming.should_not include @event
      end

      it "is scoped as 'disabled'" do
        OfferEvent.disabled.should include @event
      end
    end
  end
end
