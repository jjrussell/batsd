# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def simple_paragraphs(text)
    text = '' if text.nil?
    start_tag = tag('p', {}, true)
    text = sanitize(text)
    text.gsub!(/\r\n?/, "\n")
    text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1</p><p>')
    text.insert 0, start_tag
    text + "</p>"
  end
end
