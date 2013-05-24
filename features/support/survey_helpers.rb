SURVEY_FIELDS = {
  "Name" => "Bridge Survey",
  "Bid"  => "$1.00"
}
QUESTION = '#question_list #questions .question'

def survey_value_for(field)
  SURVEY_FIELDS[field]
end

def fill_in_survey_field(field)
  fill_in field, :with => survey_value_for(field)
  # this sucks a lot
  @name = survey_value_for("Name") if field == "Name"
end

def last_question
  page.all(QUESTION).last
end

def question_count
  page.all(QUESTION).size
end

def fill_in_question(node, type)
  @type = type
  case type
  when 'freeform text' 
    fill_in_textfield_question(node)
  when 'radio button' 
    fill_in_radio_button_question(node)
  when 'dropdown' 
    fill_in_dropdown_question(node)
  else
    raise "Invalid question type"
  end
end

def fill_in_textfield_question(node)
  within(node) do
    fill_in "Text", :with => "What is your name?"
    select "text",  :from => "Format"
  end
end

def fill_in_radio_button_question(node)
  within(node) do
    fill_in "Text", :with => "What is your quest?"
    select "radio", :from => "Format"
  end
end

def fill_in_dropdown_question(node)
  within(node) do
    fill_in "Text",     :with => "What is the average velocity of an unladen swallow?"
    select "dropdown",  :from => "Format"
  end
end

def fill_in_answers(node, type)
  within(node) do
    if type == 'radio button'
      fill_in "Responses", :with => [
        "I seek the Holy Grail.",
        "I am lost."
      ].join(';')
    elsif type == 'dropdown'
      fill_in "Responses", :with => [
        "African or European?",
        "I don't know that!"
      ].join(';')
    else
      raise "Invalid question type"
    end
  end
end

def internalize(format)
  case format
  when 'radio button'
    'radio'
  when 'freeform text'
    'text'
  when 'dropdown'
    'dropdown'
  end
end


