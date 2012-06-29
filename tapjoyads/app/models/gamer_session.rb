class GamerSession < Authlogic::Session::Base

  def referrer
   @referrer
  end

  def referrer=(referrer)
    @referrer = referrer
  end
end
