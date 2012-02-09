class ApprovalMailer < ActionMailer::Base
  def assigned(email, type, data = {})
    data[:subject] ||= "#{type.to_s.humanize} has been assigned to you"
    data[:type] = type

    handle(email, 'assigned', data)
  end

  def notification(email, type, url)
    data = {
      :subject  => "New #{type.to_s.humanize} requires approval",
      :type     => type,
      :url      => url
    }

    handle(email, 'notification', data)
  end

  def approved(email, type, data = {})
    data[:subject] ||= "#{type.to_s.humanize} has been approved on Tapjoy"
    data[:type] = type

    handle(email, "#{type}_approved", data)
  end

  def rejected(email, type, data = {})
    data[:subject] ||= "#{type.to_s.humanize} has been rejected on Tapjoy"
    data[:type] = type

    handle(email, "#{type}_rejected", data)
  end

  private
  def handle(email, template, data)
    from          'Tapjoy <noreply@tapjoy.com>'
    recipients    email
    content_type  'text/html'
    subject       data.delete(:subject)
    body          data
    template      template
  end
end
