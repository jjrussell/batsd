class OneOffs
  def self.add_percentile_currency_group
    default_group = CurrencyGroup.find_by_name('default')
    CurrencyGroup.create(default_group.attributes.merge(:rank_boost => 0, :random => 0, :name => 'percentile'))
  end
end
