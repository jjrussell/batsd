$rollout = Rollout.new(Mc)

$rollout.define_group(:admin) do |user|
  user.role_symbols.include?(:admin)
end
