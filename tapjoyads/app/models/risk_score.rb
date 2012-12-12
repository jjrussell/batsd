class RiskScore
  MIN_SCORE = 0
  MAX_SCORE = 1000
  NEUTRAL_SCORE = 500
  STARTING_SCORE = 500
  HIGH_RISK_THRESHOLD = 700
  CATEGORY_OFFSET_LIMIT = 150

  def initialize
    @profiles = { 'SYSTEM' => [], 'INDIVIDUAL' => [] }
    @rules_matched = []
    @offsets = {}
  end

  def add_offset(risk_profile)
    @profiles[risk_profile.category] << risk_profile
  end

  def rule_matched(rule)
    @rules_matched << rule
  end

  def final_score
    STARTING_SCORE + category_offset("SYSTEM") + category_offset("INDIVIDUAL") + rule_offset
  end

  def too_risky?
    final_score >= HIGH_RISK_THRESHOLD
  end

  def record_details(conversion_attempt)
    @profiles.values.each { |array| array.each { |profile| conversion_attempt.add_risk_profile(profile) } }
    @rules_matched.each { |rule| conversion_attempt.add_rule_matched(rule) }
    conversion_attempt.system_entities_offset = category_offset("SYSTEM")
    conversion_attempt.individual_entities_offset = category_offset("INDIVIDUAL")
    conversion_attempt.rules_offset = rule_offset
    conversion_attempt.final_risk_score = final_score
  end

  private

  def category_offset(category)
    return @offsets[category] if @offsets[category]

    @offsets[category] = 0.0
    return @offsets[category] if @profiles[category].empty?

    divisor = 0.0
    total = @profiles[category].inject(0.0) do |sum, profile|
      divisor += profile.weight.to_f
      sum + (profile.total_score_offset * profile.weight.to_f)
    end

    @offsets[category] = total / divisor * CATEGORY_OFFSET_LIMIT / RiskProfile::OFFSET_MAXIMUM
  end

  def rule_offset
    @offsets["RULES"] ||= @rules_matched.empty? ? 0.0 : @rules_matched.inject(0.0) { |sum, rule| sum + rule.score_offset }
  end
end
