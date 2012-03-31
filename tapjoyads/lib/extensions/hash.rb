class Hash
  def keep(&block)
    return self unless block_given?

    Hash[*select(&block).flatten]
  end
end
