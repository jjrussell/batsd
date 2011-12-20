class NumberHelper
  include ActionView::Helpers::NumberHelper

  @number_helper = new

  def self.method_missing(method_name, *args, &block)
    if @number_helper.respond_to?(method_name)
      @number_helper.send(method_name, *args, &block)
    else
      super
    end
  end

end
