Factory.define :store_click do |click|
  click.key { "#{Factory.next(:udid)}.#{Factory.next(:guid)}" }
end
