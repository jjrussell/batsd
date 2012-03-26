module ActsAsTrackable

  def self.included(base)
    base.extend ActsAsTrackable::ClassMethods
  end

  module ClassMethods
    def acts_as_trackable(options = {})

      include ActsAsTrackable::InstanceMethods

      cattr_accessor :acts_as_trackable_options
      self.acts_as_trackable_options = options
    end
  end

  module InstanceMethods
    def create_tracking_offer_for(tracked_for, options = {})
      offer_options       = {
        :item             => self,
        :tracking_for     => tracked_for,
        :partner          => partner,
        :name             => name,
        :device_types     => Offer::ALL_DEVICES.to_json,
        :price            => 0,
        :bid              => 0,
        :min_bid_override => 0,
        :rewarded         => false,
        :name_suffix      => 'tracking',
        :url_overridden   => false,
        :tapjoy_enabled   => true,
      }
      trackable_options = acts_as_trackable_options.inject({}) { |result, (key,val)| result[key] = instance_eval(&val); result }
      Offer.create!(offer_options.merge(trackable_options).merge(options))
    end
  end

end

module ActsAsTracking
  def self.included(base)
    base.extend ActsAsTracking::ClassMethods
  end

  module ClassMethods
    def acts_as_tracking
      include ActsAsTracking::InstanceMethods

      belongs_to :tracking_for, :polymorphic => true
      
      validates_presence_of :tracking_for, :if => Proc.new { |offer| offer.tracking_for_id? || offer.tracking_for_type? }
      
      after_save :disable_other_tracking_offers
    end
  end

  module InstanceMethods
    def tracking?
      tracking_for_id? && tracking_for_type?
    end

    def disable_other_tracking_offers
      if tapjoy_enabled?
        self.class.scoped(:conditions => [ 'tracking_for_id = ? AND tracking_for_type = ? AND tapjoy_enabled = true AND id != ?', tracking_for_id, tracking_for_type, id ]).find_each do |offer|
          offer.update_attribute(:tapjoy_enabled, false)
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActsAsTrackable)
ActiveRecord::Base.send(:include, ActsAsTracking)
