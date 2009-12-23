xml.instruct!
xml.apps(:type => "array") do
  @apps.each do |app|
    xml << render(:partial => "app", :object => app)
  end  
end