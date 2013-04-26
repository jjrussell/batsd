module Device::Risk
  def suspend!(num_hours)
    self.suspension_expires_at = Time.now + num_hours.hours
    save
  end

  def unsuspend
    self.delete 'suspension_expires_at'
  end

  def unsuspend!
    unsuspend
    save
  end

  def suspended?
    if suspension_expires_at?
      if suspension_expires_at > Time.now
        true
      else
        self.delete 'suspension_expires_at'
        save and return false
      end
    end
  end

  def can_view_offers?
    !(opted_out? || banned? || suspended?)
  end

  def ban(new_status = true)
    if self.banned != new_status
      self.banned = new_status
      if self.save
        web_request = WebRequest.new(:time => Time.zone.now)
        web_request.path       = 'banned_device'
        web_request.udid       = self.id
        web_request.ban_action = new_status ? 'Banned' : 'Unbanned'
      end
      web_request
    end
  end
end
