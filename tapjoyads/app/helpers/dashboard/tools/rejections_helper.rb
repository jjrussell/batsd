module Dashboard::Tools::RejectionsHelper
  def get_carriers
    Carriers::MCC_MNC_TO_CARRIER_NAME.each_with_object({}) { |pair, hash| hash[:"#{pair.last}: #{pair.first}"] = pair.first }.sort
  end
end
