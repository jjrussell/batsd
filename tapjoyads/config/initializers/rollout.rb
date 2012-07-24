$rollout = Rollout.new($redis)

$rollout.define_group(:admin) do |user|
  user.role_symbols.include?(:admin)
end
