class ObjectEncryptor < SymmetricCrypto
  def self.encrypt(object, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    super(Marshal.dump(object), key, cipher_type).unpack("H*").first
  end

  def self.decrypt(crypted, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
    packed = [ crypted ].pack("H*")
    Marshal.load(super(packed, key, cipher_type))
  end
end

