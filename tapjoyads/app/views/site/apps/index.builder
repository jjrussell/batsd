xml.instruct!
xml.apps(:type => "array") do
  xml << render(:partial => "app", :collection => @apps)
end