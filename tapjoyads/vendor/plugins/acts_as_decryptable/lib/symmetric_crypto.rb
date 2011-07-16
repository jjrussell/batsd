class SymmetricCrypto
  def self.encrypt(text, key)
    aes(:encrypt, text, key)
  end

  def self.decrypt(crypted, key)
    aes(:decrypt, crypted, key)
  end

  def self.encrypt_data_param(data)
    self.encrypt(Marshal.dump(data), SYMMETRIC_CRYPTO_SECRET).unpack("H*").first
  end

private
  def self.aes(direction, message, key)
    cipher = OpenSSL::Cipher.new('AES256')
    direction == :encrypt ? cipher.encrypt : cipher.decrypt
    cipher.key = key
    cipher.update(message) + cipher.final
  end
end
