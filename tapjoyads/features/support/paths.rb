def path_for(page)
  case page
  when "edit survey"
    "/dashboard/tools/survey_offers/#{@survey.id}/edit"
  when 'show offer'
    "/dashboard/statz/#{@survey.id}"    
  when "edit offer" 
    "/dashboard/statz/#{@survey.offer.id}/edit"
  else 
    raise "no path for page \"#{page}\""
  end
end

