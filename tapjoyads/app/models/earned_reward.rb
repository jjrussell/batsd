class EarnedReward < SimpledbResource
  def initialize(key, options = {})
    super 'earned_reward', key, options
  end
end