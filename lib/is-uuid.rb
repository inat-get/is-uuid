# frozen_string_literal: true

require 'time'
require 'openssl'
require 'securerandom'

class UUID

  attr_reader :bytes, :high, :low

  def initialize bytes
    @bytes = bytes
    @high, @low = @bytes.unpack "Q>Q>"
  end

  include Comparable

  class << self

    def parse source
      return UUID::NIL if source.nil?
      return source if source.is_a?(UUID)
      raise ArgumentError, "Invalid source: #{ source.inspect }", caller_locations unless source.is_a?(String)
      raise ArgumentError, "Invalid source format: #{ source.inspect }", caller_locations unless valid?(source)
      new(parse_bytes(source)).freeze
    end

    alias :'[]' :parse

    def generate **opts
      version = opts[:version] || opts[:v] || 4
      case version
      when 1, :v1
        new(generate_v1_bytes).freeze
      when 3, :v3
        new(generate_v3_bytes(**opts)).freeze
      when 4, :v4
        new(parse_bytes(SecureRandom.uuid_v4)).freeze
      when 5, :v5
        new(generate_v5_bytes(**opts)).freeze
      when 7, :v7
        new(parse_bytes(SecureRandom.uuid_v7)).freeze
      when 8, :v8, :custom
        new(generate_v8_bytes(**opts)).freeze
      else
        raise ArgumentError, "Unsupported UUID version: #{ version.inspect }", caller_locations
      end
    end

    def valid? source
      case source
      when UUID
        source.valid?
      when String
        source =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      else
        false
      end
    end

    private :new

    private

    def parse_bytes source
      source.downcase.gsub(/[-\s]/, "").scan(/.{2}/).map { |h| h.hex }.pack("C*")
    end

    def generate_v1_bytes
      timestamp_ns = gregorian_timestamp
      time_low = timestamp_ns & 0xFFFFFFFF
      time_mid = (timestamp_ns >> 32) & 0xFFFF
      time_hi_version = ((timestamp_ns >> 48) & 0x0FFF) | 0x1000
      clock_seq = SecureRandom.random_number(0x4000)
      clock_seq_hi_var = (clock_seq >> 8) | 0x80
      clock_seq_low = clock_seq & 0xFF
      node = SecureRandom.bytes(6)
      [
        time_low, 
        time_mid, 
        time_hi_version, 
        clock_seq_hi_var, 
        clock_seq_low, 
        node
      ].pack 'NnnCCA6'
    end

    def gregorian_timestamp
      # 1582-10-15 00:00:00 UTC → 0x01b21dd213814000
      epoch = 0x01b21dd213814000
      now_ns = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond).to_i
      (now_ns + epoch).to_i
    end

    def generate_v3_bytes **opts
      ns = opts[:namespace] || opts[:ns]
      raise ArgumentError, "Invalid namespace: #{ ns.inspect }", caller_locations[1..] unless ns.is_a?(String) && valid?(ns)
      namespace = parse(ns).bytes
      name = opts[:name]
      raise ArgumentError, "Invalid name: #{ name.inspect }", caller_locations[1..] unless name.is_a?(String)
      digest = OpenSSL::Digest::MD5.digest(namespace + name)
  
      # Version 3 + RFC4122 variant
      digest.setbyte 6, (digest.getbyte(6) & 0x0F) | 0x30
      digest.setbyte 8, (digest.getbyte(8) & 0x3F) | 0x80
      digest
    end

    def generate_v5_bytes **opts
      ns = opts[:namespace] || opts[:ns]
      raise ArgumentError, "Invalid namespace: #{ns.inspect}", caller_locations[1..] unless ns.is_a?(String) && valid?(ns)
      namespace = parse(ns).bytes
      name = opts[:name]
      raise ArgumentError, "Invalid name: #{name.inspect}", caller_locations[1..] unless name.is_a?(String)
      digest = OpenSSL::Digest::SHA1.digest(namespace + name)[0, 16]
  
      # Version 5 + RFC4122 variant
      digest.setbyte 6, (digest.getbyte(6) & 0x0F) | 0x50
      digest.setbyte 8, (digest.getbyte(8) & 0x3F) | 0x80
      digest
    end

    def generate_v8_bytes **opts
      prefix = opts[:prefix] || opts[:bytes]
      bytes = prepare_six(prefix) + SecureRandom.bytes(10).unpack('C*')
      bytes[6] = (bytes[6] & 0x0F) | 0x80
      bytes[8] = (bytes[8] & 0x3F) | 0x80
      bytes.pack 'C*'
    end

    def prepare_six prefix
      case prefix
      when nil
        SecureRandom.bytes(6).unpack('C*')
      when String
        raise ArgumentError, "Prefix too long: #{ prefix.inspect }", caller_locations[2..] if prefix.length > 6
        prefix.unpack('C*') + SecureRandom.bytes(6 - prefix.length).unpack('C*')
      when Array
        raise ArgumentError, "Prefix too long: #{ prefix.inspect }", caller_locations[2..] if prefix.size > 6
        prefix + SecureRandom.bytes(6 - prefix.size).unpack('C*')
      when Integer
        raise ArgumentError, "Prefix too big: #{ prefix }", caller_locations[2..] if prefix > 0xFF_FF_FF_FF_FF_FF || prefix < 0
        packed = [ prefix ].pack('Q>')
        bytes = packed.bytes.drop_while { |d| d == 0 }
        raise ArgumentError, "Prefix too big: #{ prefix }", caller_locations[2..] if bytes.size > 6
        bytes + SecureRandom.bytes(6 - bytes.size).unpack('C*')
      else
        raise ArgumentError, "Invalid prefix: #{ prefix.inspect }", caller_locations[2..]
      end
    end

  end

  NIL = parse '00000000-0000-0000-0000-000000000000'

  def eql? other
    return true if equal?(other)
    return false unless other.is_a?(UUID)

    @high == other.high && @low == other.low
  end

  def hash
    @high.hash ^ @low.hash
  end

  def <=> other
    return 0 if equal?(other)
    return nil unless other.is_a?(UUID)

    h1, l1 = @high, @low
    h2, l2 = other.high, other.low

    return 0 if h1 == h2 && l1 == l2
    return 1 if h1 > h2 || (h1 == h2 && l1 > l2)
    -1
  end

  def to_s
    @bytes.unpack1("H*").insert(8, "-").insert(13, "-").insert(18, "-").insert(23, "-").downcase.freeze
  end

  def inspect
    "\#<UUID:#{ version }:#{ variant }:#{ to_s }>".freeze
  end

  def urn
    "urn:uuid:#{ to_s }".freeze
  end

  def to_i
    @low + (@high << 64)
  end

  def to_a
    @bytes.unpack 'C*'
  end

  def version
    (@bytes.getbyte(6) & 0xF0) >> 4
  end

  def variant
    case (@bytes.getbyte(8) >> 6)
    when 0b00
      0  # NCS (0xxx)
    when 0b10 
      1  # RFC4122 (10xx)
    when 0b11 then 
      2  # Microsoft (110x)
    else 
      3  # reserved (111x)
    end
  end

  VALID_VERSIONS = [ 1, 3, 4, 5, 7, 8 ].freeze
  VALID_VARIANTS = [ 0, 1, 2 ].freeze

  private_constant :VALID_VERSIONS, :VALID_VARIANTS

  def valid?
    return true if self == NIL
    return false unless @bytes.bytesize == 16
    VALID_VERSIONS.include?(version) && VALID_VARIANTS.include?(variant)
  end

end
