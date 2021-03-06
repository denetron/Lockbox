require 'openssl'
require 'base64'

class Lockbox

  @@locked = true
  @@public_key = nil
  @@private_key = nil

  def self.locked?
    return @@locked
  end

  def self.unlocked?
    return !@@locked
  end

  def self.try? (pass_phrase)
    @@config ||= YAML::load_file("#{RAILS_ROOT}/config/lockbox.yml")[RAILS_ENV]
    if pass_phrase.nil? and @@config['pass_phrase'].nil?
      false
    else
      begin
        @@private_key = OpenSSL::PKey::RSA.new(File.read(@@config['private_key_path']), pass_phrase||@@config['pass_phrase'])
        @@locked = false
        true
      rescue OpenSSL::PKey::RSAError
        false
      end
    end
  end

  def self.lock!
    @@private_key = nil
    @@locked = true
  end

  def self.encrypt(val)
    if val.is_a? String
      @@config ||= YAML::load_file("#{RAILS_ROOT}/config/lockbox.yml")[RAILS_ENV]
      if @@public_key.nil?
        begin
          @@public_key = OpenSSL::PKey::RSA.new(File.read(@@config['public_key_path']))
        rescue
          return false
        end
      end
      Base64.encode64(@@public_key.public_encrypt(val))
    end
  end

  def self.decrypt(val)
    if locked?
      raise StillLockedException, "Passphrase not provided to lockbox."
    elsif val.is_a? String
      @@private_key.private_decrypt(Base64.decode64(val))
    end
  end

end

class StillLockedException < RuntimeError
end
