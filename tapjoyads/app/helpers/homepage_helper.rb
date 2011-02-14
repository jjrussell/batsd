module HomepageHelper
  def press_contact(person)
    concat(person[:name])
    concat("<br/>")
    concat(person[:company])
    concat("<br/>")
    concat(person[:phone])
    concat("<br/>")
    concat(mail_to(person[:email]))
    concat("<br/>")
    concat("<br/>")
  end
end
