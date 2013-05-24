def mutator_for(field)
  case field
  when 'callback URL'
    FactoryGirl.generate(:callback_url)
  when 'conversion rate'
    FactoryGirl.generate(:conversion_rate)
  when 'currency name'
    FactoryGirl.generate(:name)
  else
    raise "no selector for #{name}"
  end
end
