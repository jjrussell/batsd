def path_for(page)
  case page
  when "edit survey"
    "/dashboard/tools/survey_offers/#{@survey.id}/edit"
  when 'statz show offer'
    "/dashboard/statz/#{@offer.id}"
  when "statz edit offer"
    "/dashboard/statz/#{@offer.id}/edit"
  when "edit currency"
    "/dashboard/apps/#{@currency.app.id}/currencies/#{@currency.id}"
  when "show currency"
    path_for('edit currency')
  else
    raise "no path for page \"#{page}\""
  end
end
