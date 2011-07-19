class SymmetricCrypto
  def self.encrypt(text, key)
    aes(:encrypt, text, key)
  end

  def self.decrypt(crypted, key)
    aes(:decrypt, crypted, key)
  end

  def self.encrypt_object(object, key)
    self.encrypt(Marshal.dump(object), key).unpack("H*").first
  end

  def self.decrypt_object(crypted, key)
    data_str = SymmetricCrypto.decrypt([ crypted ].pack("H*"), key)
    Marshal.load(data_str)
  end

private
  def self.aes(direction, message, key)
    cipher = OpenSSL::Cipher.new('AES256')
    direction == :encrypt ? cipher.encrypt : cipher.decrypt
    cipher.key = key
    cipher.update(message) + cipher.final
  end
end
