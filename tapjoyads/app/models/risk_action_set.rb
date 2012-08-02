class RiskActionSet
  # All possible actions are listed here. The set may not contain more than one of each action,
  # and no more than one action from each array (group) defined in POSSIBLE_ACTIONS.
  # Actions are listed in order of precedence. If two actions from the same group are
  # added to the set, only the one with higher precedence will remain.
  POSSIBLE_ACTIONS = [
    ['BLOCK', 'DELAY48', 'DELAY24'],
    ['FLAG'],
    ['BAN', 'SUSPEND72', 'SUSPEND24'],
  ]

  SUPERSEDING_ACTIONS = {}
  SUPERSEDED_ACTIONS = {}
  POSSIBLE_ACTIONS.each do |array|
    if array.size > 1
      superseders = array.clone
      array.reverse.each do |action|
        superseders.delete(action)
        SUPERSEDING_ACTIONS[action] = superseders.clone unless superseders.empty?
      end
      supersedes = array.clone
      array.each do |action|
        supersedes.delete(action)
        SUPERSEDED_ACTIONS[action] = supersedes.clone unless supersedes.empty?
      end
    end
  end

  def initialize
    @actions = Set.new
  end

  def actions
    @actions.clone
  end

  def add(action)
    return self unless POSSIBLE_ACTIONS.flatten.include?(action)
    return self if superseded?(action)
    @actions -= SUPERSEDED_ACTIONS[action] if SUPERSEDED_ACTIONS[action]
    @actions.add(action)
    self
  end

  def merge(actions)
    actions.each {|action| add(action)}
    self
  end

  private

  def superseded?(action)
    SUPERSEDING_ACTIONS[action] && !(@actions&SUPERSEDING_ACTIONS[action]).empty?
  end
end
