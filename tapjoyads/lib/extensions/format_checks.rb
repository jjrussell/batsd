module FormatChecks
  UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  UDID_REGEX = /^[a-f0-9]{40}$/

  def uuid?
    self =~ UUID_REGEX
  end

  def udid?
    self =~ UDID_REGEX
  end
end

class String
  include FormatChecks
end

class NilClass
  include FormatChecks
end
