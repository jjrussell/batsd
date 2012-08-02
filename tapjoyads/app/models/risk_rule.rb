class RiskRule
  attr_accessor :name, :score_offset, :recommended_actions, :pattern, :message

  def initialize(name, score_offset, pattern, recommended_actions = nil)
    self.name = name
    self.score_offset = score_offset
    self.pattern = pattern
    self.recommended_actions = recommended_actions
  end
end
