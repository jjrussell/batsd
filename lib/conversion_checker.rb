class ConversionChecker
  include ConversionChecker::Rules
  attr_accessor :risk_message

  def initialize(click, conversion_attempt)
    @click = click
    @conversion_attempt = conversion_attempt

    @recommended_actions = RiskActionSet.new
    @entity_keys = []
    @resolution_update_keys = []

    @offer = Offer.find_in_cache(@click.offer_id, :do_lookup => true)
    @entity_keys << "OFFER.#{@offer.id}"
    @entity_keys << "ADVERTISER.#{@offer.partner_id}"

    @currency = Currency.find_in_cache(@click.currency_id, :do_lookup => true)
    @entity_keys << "APP.#{@currency.app_id}"
    @entity_keys << "PUBLISHER.#{@currency.partner_id}"

    @publisher_user = PublisherUser.for_click(@click)
    @entity_keys << "USER.#{@publisher_user.key}"

    @device = Device.new(:key => @click.udid)
    @entity_keys << "DEVICE.#{@device.key}"
    @resolution_update_keys << "DEVICE.#{@device.key}"

    @entity_keys << "IPADDR.#{@click.ip_address}"
    @resolution_update_keys << "IPADDR.#{@click.ip_address}"
    @entity_keys << "COUNTRY.#{@click.country}"

    initialize_rules
  end

  def acceptable_risk?

    unless @publisher_user.update!(@click.udid)
      @risk_message = "TooManyUdidsForPublisherUserId" and return block_conversion
    end

    other_devices = (@publisher_user.udids - [ @click.udid ]).map { |udid| Device.new(:key => udid) }

    banned_devices = (other_devices + [ @device ]).select(&:banned?)
    if banned_devices.present?
      @risk_message = "Banned (UDID=#{banned_devices.map(&:key).join ', '})" and return block_conversion
    end

    suspended_devices = (other_devices + [ @device ]).select(&:suspended?)
    if suspended_devices.present?
      @risk_message = "Suspended (UDID=#{suspended_devices.map(&:key).join ', '})" and return block_conversion
    end

    # Do not reward if user has installed this app for the same publisher user id on another device
    unless @offer.multi_complete? || @offer.video_offer?
      other_devices.each do |d|
        if d.has_app?(@click.advertiser_app_id)
          @risk_message = "AlreadyRewardedForPublisherUserId (UDID=#{d.key})" and return block_conversion
        end
      end
    end

    if too_risky?
      @risk_message = "Conversion risk is too high: #{@risk_score.final_score}" and return block_conversion
    end

    true
  end

  def process_conversion(reward)
    @resolution_update_keys.each do |key|
      risk_profile = RiskProfile.new(:key => key)
      risk_profile.process_conversion(reward)
    end
  end

  private

  def block_conversion
    @resolution_update_keys.each do |key|
      risk_profile = RiskProfile.new(:key => key)
      risk_profile.process_block
    end
    false
  end

  def too_risky?
    return false unless @currency.partner_enable_risk_management?

    @risk_score = RiskScore.new
    @entity_keys.each do |key|
      risk_profile = RiskProfile.new(:key => key)
      @risk_score.add_offset(risk_profile)
    end
    evaluate_rules
    update_conversion_attempt

    if @recommended_actions.actions.include?('BAN')
      @device.banned = true
      @device.save
    elsif @recommended_actions.actions.include?('SUSPEND24')
      @device.suspend!(24)
    elsif @recommended_actions.actions.include?('SUSPEND72')
      @device.suspend!(72)
    end
    @risk_score.too_risky? || blocked_by_rule?
  end

  def blocked_by_rule?
    @recommended_actions.actions.include?('BLOCK')
  end

  def update_conversion_attempt
    @conversion_attempt.clear_history
    @risk_score.record_details(@conversion_attempt)
    @conversion_attempt.processed_actions = @recommended_actions.actions
    @conversion_attempt.save
  end

  def evaluate_rules
    @rules.each do |rule|
      if rule.pattern.call
        @recommended_actions.merge(rule.recommended_actions) if rule.recommended_actions
        if @rule_message
          rule.message = @rule_message
          @rule_message = nil
        end
        @risk_score.rule_matched(rule)
      end
    end
  end
end
