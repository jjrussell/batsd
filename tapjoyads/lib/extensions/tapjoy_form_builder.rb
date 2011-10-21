class TapjoyFormBuilder < ActionView::Helpers::FormBuilder
  def select(method, choices, options = {}, html_options = {})
    (html_options[:multiple] ? hidden_field(method, :name => "#{@object_name}[#{method}][]", :value => "") : "") + super(method, choices, options, html_options)
  end
end

ActionView::Base.default_form_builder = TapjoyFormBuilder
