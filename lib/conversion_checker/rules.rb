module ConversionChecker::Rules
  DEVICE_VELOCITY_LIMIT_24 = 10000
  DEVICE_VELOCITY_LIMIT_72 = 20000
  IPADDR_VELOCITY_LIMIT_24 = 40000
  IPADDR_VELOCITY_LIMIT_72 = 100000
  BLOCKED_CONVERSION_LIMIT_8 = 4

  private

  def initialize_rules
    @rules = [
      RiskRule.new(
        'device_velocity_check_24',
        150,
        Proc.new do
          # Exclude udid sent for all users by bad integration in Ludia
          next false if IGNORED_UDIDS.include?(@device.key)

          risk_profile = RiskProfile.new(:key => "DEVICE.#{@device.key}")
          next false unless risk_profile
          if risk_profile.revenue_total(24) - @click.advertiser_amount > DEVICE_VELOCITY_LIMIT_24
            @rule_message = "Conversion revenue of #{-@click.advertiser_amount} added to last 24 hour revenue of #{risk_profile.revenue_total(24)} would exceed limit."
            true
          end
        end,
        ['BLOCK', 'SUSPEND24']
      ),
      RiskRule.new(
        'device_velocity_check_72',
        125,
        Proc.new do
          # Exclude udid sent for all users by bad integration in Ludia
          next false if IGNORED_UDIDS.include?(@device.key)

          risk_profile = RiskProfile.new(:key => "DEVICE.#{@device.key}")
          next false unless risk_profile
          if risk_profile.revenue_total(72) - @click.advertiser_amount > DEVICE_VELOCITY_LIMIT_72
            @rule_message = "Conversion revenue of #{-@click.advertiser_amount} added to last 72 hour revenue of #{risk_profile.revenue_total(72)} would exceed limit."
            true
          end
        end,
        ['BLOCK', 'SUSPEND24']
      ),
      RiskRule.new(
        'ipaddr_velocity_check_24',
        125,
        Proc.new do
          risk_profile = RiskProfile.new(:key => "IPADDR.#{@click.ip_address}")
          next false unless risk_profile
          if risk_profile.revenue_total(24) - @click.advertiser_amount > IPADDR_VELOCITY_LIMIT_24
            @rule_message = "Conversion revenue of #{-@click.advertiser_amount} added to last 24 hour revenue of #{risk_profile.revenue_total(24)} would exceed limit."
            true
          end
        end,
        ['BLOCK']
      ),
      RiskRule.new(
        'ipaddr_velocity_check_72',
        100,
        Proc.new do
          risk_profile = RiskProfile.new(:key => "IPADDR.#{@click.ip_address}")
          next false unless risk_profile
          if risk_profile.revenue_total(72) - @click.advertiser_amount > IPADDR_VELOCITY_LIMIT_72
            @rule_message = "Conversion revenue of #{-@click.advertiser_amount} added to last 72 hour revenue of #{risk_profile.revenue_total(72)} would exceed limit."
            true
          end
        end,
        ['BLOCK']
      ),
      RiskRule.new(
        'country_mismatch',
        100,
        Proc.new do
          unless @click.country == @click.geoip_country
            @rule_message = "Device country (#{@click.country}) doesn't match GEOIP country (#{@click.geoip_country})."
            true
          end
        end
      ),
      RiskRule.new(
        'previous_blocked_transactions_8',
        150,
        Proc.new do
          risk_profile = RiskProfile.new(:key => "DEVICE.#{@device.key}")
          next false unless risk_profile
          if risk_profile.block_count(8) > BLOCKED_CONVERSION_LIMIT_8
            @rule_message = "#{risk_profile.block_count(8)} blocked conversions in the last 8 hours exceeds limit."
            true
          end
        end,
        ['BLOCK']
      ),
    ]
  end
end
