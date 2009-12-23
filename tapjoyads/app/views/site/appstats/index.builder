xml.instruct!
xml.appstats(:type => "array") do
  if  @appstat_list.size > 0
    xml << render(:partial => "appstat", :collection => @appstat_list)
  end  
end