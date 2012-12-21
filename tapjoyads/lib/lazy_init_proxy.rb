require 'blankslate'

class LazyInitProxy < BlankSlate
  def initialize(&block)
    @initializer = block
  end

  # Forget the object so it will be recreated
  def reset_proxy!
    @object = nil
  end

  def respond_to?(method)
    method = method.to_sym
    [:reset_proxy!].include?(method) || @object.respond_to?(method)
  end

private

  def method_missing(meth, *args, &block)
    @object ||= @initializer.call

    @object.__send__(meth, *args, &block)
  end
end