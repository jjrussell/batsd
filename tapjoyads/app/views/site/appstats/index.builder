xml.instruct!
xml.appstats(:type => "array") do
  xml << render(:partial => "appstat", :collection => @appstat_list)
end