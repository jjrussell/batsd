class ObjectEncryptor < SymmetricCrypto
  def self.encrypt(object, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    super(Marshal.dump(object), key, cipher_type).unpack("H*").first
  end

  def self.decrypt(crypted, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    packed = [ crypted ].pack("H*")
    Marshal.load(super(packed, key, cipher_type))
  end

  def self.encrypt_url(url, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    url = URI.parse(url)
    params = CGI.parse(url.query)
    params.each { |k, v| params[k] = v.first }
    url.query = "data=#{encrypt(params)}"
    url.to_s
  end
end

