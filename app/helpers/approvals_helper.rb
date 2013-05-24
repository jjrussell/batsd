module ApprovalsHelper
  def options_for_approval_state
    states = Approval.options_for_state
    states.map do |state|
      state[0] = 'Accepted' if state[0] == 'Approved'
      state
    end
  end
end
