class AdOrder
  attr_accessor :RotationTime, :RotationDirection, :HasLocation, :LastNetwork, :networks

  def initialize()
    @RotationTime = "0"
    @RotationDirect = "0"
    @HasLocation = "False"
    @LastNetwork = "0"
  end
end
