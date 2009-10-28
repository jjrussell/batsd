class HelloWorldProcessor < ApplicationProcessor

  subscribes_to :hello_world

  def on_message(message)
    logger.info "HelloWorldProcessor received: " + message
  end
end