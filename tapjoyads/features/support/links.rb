def link_for(description)
  case description
  when "with the name of the survey that goes to the offer detail page"
    return @survey.name, path_for('statz show offer')
  when "to the survey's offerwall view"
    return 'Offerwall view', "/survey_results/new?click_key=just_looking&id=#{@survey.id}&udid=just_looking"
  when "to enable the survey"
    return 'Enable', "/dashboard/tools/survey_offers/#{@survey.id}/toggle_enabled"
  when "to edit the survey"
    return 'Edit', "/dashboard/tools/survey_offers/#{@survey.id}/edit"
  when "to remove the survey"
    return 'Remove', "/dashboard/tools/survey_offers/#{@survey.id}", 'delete'
  when nil
    raise "can't be nil"
  else
    raise "no link matching description '#{description}'"
  end
end
