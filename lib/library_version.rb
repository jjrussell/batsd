class LibraryVersion
  attr_reader :version

  class <<self
    def capabilities
      @capabilities ||= Array.new
    end

    def capability(name, version, matcher=:>=)
      capabilities << name

      define_method(name) do
        version
      end
      define_method("#{name}?") do
        send(matcher, version)
      end
    end
  end

  capability :sdkless_integration,   SDKLESS_MIN_LIBRARY_VERSION
  capability :control_video_caching, '8.3.0'

  def initialize(version)
    @version = version.to_s
  end

  def >(other);  version.version_greater_than?(other); end
  def >=(other); version.version_greater_than_or_equal_to?(other); end
  def <=(other); version.version_less_than_or_equal_to?(other); end
  def <(other);  version.version_less_than?(other); end
  def ==(other); version == other; end
  def to_s;      version; end
  def capabilities; self.class.capabilities; end
end

