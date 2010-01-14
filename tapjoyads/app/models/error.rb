# TODO: Don't use this domain any more. Report errors to new-relic instead.
class Error < SimpledbResource
  self.domain_name = 'error'
  
  def initialize(options = {})
    super({:load => false}.merge(options))
  end
end