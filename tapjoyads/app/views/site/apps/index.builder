xml.instruct!
xml.apps(:type => "array") do
  if @apps.size > 0
    xml << render(:partial => "app", :collection => @apps)
  end 
end