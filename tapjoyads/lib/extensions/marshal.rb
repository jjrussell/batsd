module Marshal
  def self.safe_restore(source)
    begin
      Marshal.restore(source)
    rescue ArgumentError => e
      if e.message.match /undefined class\/module (.+)$/
        $1.constantize
        retry
      end
    end
  end
end
