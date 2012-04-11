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
    def build_tracking_offer_for(tracked_for, options = {})
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
      trackable_options = acts_as_trackable_options.inject({}) { |result, (key,val)| result[key] = val.is_a?(Symbol) ? send(val) : instance_eval(&val); result }
      Offer.new(offer_options.merge(trackable_options).merge(options))
    end

    def find_tracking_offer_for(tracked_for)
      offers.tracked_for(tracked_for).first
    end

    def create_tracking_offer_for(tracked_for, options = {})
      build_tracking_offer_for(tracked_for, options).tap do |offer|
        offer.save!
      end
    end

    def find_or_build_tracking_offer_for(tracked_for, options = {})
      find_tracking_offer_for(tracked_for) || build_tracking_offer_for(tracked_for, options)
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
      named_scope :tracked_for, lambda { |tracking_for| { :conditions => [ "tracking_for_type = ? and tracking_for_id = ?", tracking_for.class.name, tracking_for.id ] } }
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

module HasTrackingOffers
  def self.included(base)
    base.extend HasTrackingOffers::ClassMethods
  end

  module ClassMethods
    def has_tracking_offers
      include HasTrackingOffers::InstanceMethods
      has_many :tracking_offers, :class_name => 'Offer', :as => :tracking_for
      has_one :tracking_offer, :class_name => 'Offer', :as => :tracking_for, :conditions => 'tapjoy_enabled = true'
      after_save :enable_tracking_offer
    end
  end

  module InstanceMethods
    def tracking_item=(tracking_item)
      if tracking_item.present?
        self.tracking_offer = tracking_item.find_or_build_tracking_offer_for(self)
      else
        self.tracking_offer = nil
      end
    end

    def tracking_source_offer=(tracking_source_offer)
      if tracking_source_offer.present?
        self.tracking_item = tracking_source_offer.item
      else
        self.tracking_item = nil
      end
    end

    def tracking_source_offer_id=(tracking_source_offer_id)
      if tracking_source_offer_id.present?
        self.tracking_source_offer = Offer.find(tracking_source_offer_id) 
      else
        self.tracking_source_offer = nil
      end
    end

    def tracking_item
      tracking_offer.try :item
    end

    def tracking_source_offer_id
      tracking_offer.try :item_id
    end

    def enable_tracking_offer
      if tracking_offer.present?
        tracking_offer.tapjoy_enabled = true 
        tracking_offer.save
      else
        tracking_offers.each do |offer|
          offer.tapjoy_enabled = false
          offer.save
        end
      end
    end

  end
end

ActiveRecord::Base.send(:include, ActsAsTrackable)
ActiveRecord::Base.send(:include, ActsAsTracking)
ActiveRecord::Base.send(:include, HasTrackingOffers)

