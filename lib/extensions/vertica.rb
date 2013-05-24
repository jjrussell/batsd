module Vertica
  class Connection
    def reset_notifications
      @notifications = []
      @notices       = []
    end
  end
end
