class SymmetricCrypto
  def self.encrypt(text, key, cipher_type = 'AES256')
    aes(:encrypt, text, key, cipher_type)
  end

  def self.decrypt(crypted, key, cipher_type = 'AES256')
    aes(:decrypt, crypted, key, cipher_type)
  end

  def self.encrypt_object(object, key, cipher_type = 'AES256')
    self.encrypt(Marshal.dump(object), key, cipher_type).unpack("H*").first
  end

  def self.decrypt_object(crypted, key, cipher_type = 'AES256')
    data_str = SymmetricCrypto.decrypt([ crypted ].pack("H*"), key, cipher_type)
    Marshal.load(data_str)
  end

private
  def self.aes(direction, message, key, cipher_type = 'AES256')
    cipher = OpenSSL::Cipher.new(cipher_type)
    direction == :encrypt ? cipher.encrypt : cipher.decrypt
    cipher.key = key
    cipher.update(message) + cipher.final
  end
end
