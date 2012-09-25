class ObjectEncryptor < SymmetricCrypto
  def self.encrypt(object, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    super(Marshal.dump(object), key, cipher_type).unpack("H*").first
  end

  def self.b64_encrypt(object, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    res = SymmetricCrypto.encrypt(Marshal.dump(object), key, cipher_type)
    [res].pack("m0*").tr('+/','-_').gsub("\n",'')
  end

  def self.decrypt(crypted, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    begin
      packed = [crypted].pack("H*")
      Marshal.load(super(packed, key, cipher_type))
    rescue
      packed = crypted.tr('_-','/+').unpack("m0*").first
      Marshal.load(super(packed, key, cipher_type))
    end
  end

  def self.encrypt_url(url, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    uri = URI.parse(url)
    uri.query = "data=#{encrypt(make_params(uri))}"
    uri.to_s
  end

  def self.b64_encrypt_url(url, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    uri = URI.parse(url)
    uri.query = "data=#{b64_encrypt(make_params(uri))}"
    uri.to_s
  end

  private

  def self.make_params(url)
    params = CGI.parse(url.query)
    params.each { |k, v| params[k] = v.first }
  end
end

