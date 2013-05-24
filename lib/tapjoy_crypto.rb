class TapjoyCrypto

  def self.encrypt(*tokens)
    unicode_password = ''
    tokens[0].each_char do |c|
      unicode_password += c + "\x00"
    end
    raw_salt = Base64::decode64(tokens[1])
    sha1 = Digest::SHA1.digest(raw_salt + unicode_password)
    Base64::encode64(sha1).strip
  end

  def self.matches?(crypted, *tokens)
    encrypt(*tokens) == crypted
  end

end
