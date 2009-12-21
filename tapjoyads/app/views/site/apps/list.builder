xml.instruct!
xml.apps do
  xml << render(:partial => "app", :collection => @apps)
end