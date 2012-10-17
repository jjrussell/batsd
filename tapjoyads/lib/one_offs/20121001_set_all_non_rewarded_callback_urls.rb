class OneOffs

  def self.set_all_non_rewarded_callback_urls
    Currency.non_rewarded.each do |c|
      c.callback_url = Currency::NO_CALLBACK_URL
      c.save!
    end
  end
end