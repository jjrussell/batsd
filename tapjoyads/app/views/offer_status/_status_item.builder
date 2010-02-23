xml.OfferStatusReturnClass do
  xml.DateInitiated status_item['created']
  xml.Instructions status_item['offerInstructions']
  xml.Name status_item['offerName']
  xml.SupportEmailAddress email
  xml.CanEmail status_item['canSubmitCSRequest']
  xml.SNUID snuid
  xml.Status status_item['status']
  xml.Type '0'
  xml.TimeDelay status_item['timeDelay']
  xml.OfferpalOfferID status_item['offerId']
  xml.UserName ''
end