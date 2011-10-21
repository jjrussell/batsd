require 'test_helper'

class OfferEventTest < ActiveSupport::TestCase
  should belong_to :offer

  should validate_presence_of :scheduled_for
  should validate_presence_of :offer

  context "An OfferEvent scheduled for the future" do
    setup do
      @event = Factory(:offer_event, :scheduled_for => 1.hour.from_now)
    end

    should "be scoped as 'upcoming'" do
      assert OfferEvent.upcoming.include?(@event)
    end

    should "not be scoped as 'to_run'" do
      assert !OfferEvent.to_run.include?(@event)
    end
  end

  context "An OfferEvent scheduled for the past" do
    setup do
      @event = Factory(:offer_event)
      @event.scheduled_for = 1.hour.ago
      @event.save(false)
    end

    should "be scoped as 'to_run' and 'upcoming'" do
      assert OfferEvent.to_run.include?(@event)
      assert OfferEvent.upcoming.include?(@event)
    end

    context "after being run" do
      setup do
        @event.run!
      end

      should "no longer be scoped as 'to_run' or 'upcoming'" do
        assert !OfferEvent.to_run.include?(@event)
        assert !OfferEvent.upcoming.include?(@event)
      end

      should "be scoped as 'completed'" do
        assert OfferEvent.completed.include?(@event)
      end
    end

    context "after being disabled" do
      setup do
        @event.disable!
      end

      should "no longer be scoped as 'to_run' or 'upcoming'" do
        assert !OfferEvent.to_run.include?(@event)
        assert !OfferEvent.upcoming.include?(@event)
      end

      should "be scoped as 'disabled'" do
        assert OfferEvent.disabled.include?(@event)
      end
    end
  end

end
