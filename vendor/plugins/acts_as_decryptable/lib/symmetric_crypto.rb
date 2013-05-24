class SymmetricCrypto
  def self.encrypt(text, key, cipher_type = 'AES256')
    aes(:encrypt, text, key, cipher_type)
  end

  def self.decrypt(crypted, key, cipher_type = 'AES256')
    aes(:decrypt, crypted, key, cipher_type)
  end

private
  def self.aes(direction, message, key, cipher_type = 'AES256')
    cipher = OpenSSL::Cipher.new(cipher_type)
    direction == :encrypt ? cipher.encrypt : cipher.decrypt
    cipher.key = key
    cipher.update(message) + cipher.final
  end
end
