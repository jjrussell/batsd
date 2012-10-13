def path_for(page)
  case page
  when "edit survey"
    "/dashboard/tools/survey_offers/#{@survey.id}/edit"
  when 'show offer'
    "/dashboard/statz/#{@survey.id}"
  when "edit offer"
    "/dashboard/statz/#{@survey.primary_offer.id}/edit"
  when "edit currency" 
    "/dashboard/apps/#{@currency.app.id}/currencies/#{@currency.id}"
  when "show currency" 
    path_for('edit currency')
  else
    raise "no path for page \"#{page}\""
  end
end
