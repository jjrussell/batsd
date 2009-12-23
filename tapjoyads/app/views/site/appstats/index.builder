xml.instruct!
xml.appsstats do
  xml << render(:partial => "appstat", :collection => @appstat_list)
end