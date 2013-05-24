module Dashboard::AppsHelper
  def pay_per_click_selections(current_selection)
    options_for_select([["Non Pay-Per-Click", Offer::PAY_PER_CLICK_TYPES[:non_ppc]],
      ["Pay-Per-Click on Offerwall", Offer::PAY_PER_CLICK_TYPES[:ppc_on_offerwall]],
      ["Pay-Per-Click on Instruction Page", Offer::PAY_PER_CLICK_TYPES[:ppc_on_instruction]]],
       current_selection)
  end
end
