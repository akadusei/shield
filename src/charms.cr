annotation Memoize
end

class Object
  macro inherited
    macro method_added(method)
      \{% if method.annotation(Memoize) %}
        memoize(\{{ method }})
      \{% end %}
    end
  end
end

module MailHelpers
  def mail(email : Carbon::Email.class, *args, **kwargs) : Nil
    email.new(*args, **kwargs).deliver
  end

  def mail_later(email : Carbon::Email.class, *args, **kwargs) : Nil
    email.new(*args, **kwargs).deliver_later
  end
end

class String
  # References:
  #
  # - https://en.wikipedia.org/wiki/Email_address
  # - https://support.google.com/mail/answer/9211434
  def email? : Bool
    address, _, domain = partition('@')
    return false if address.empty? || address.size > 64 || !domain.domain?
    address.matches?(/^[a-z\_](?:[a-z0-9\_]*(?<!\.)\.?)*(?<!\.)$/i)
  end

  # Reference: https://en.wikipedia.org/wiki/Domain_Name_System
  def domain? : Bool
    return false if empty? || size > 253

    matches?(
      /^(?:[a-z0-9][a-z0-9\-]{0,62}(?<!\-)\.)+[a-z][a-z0-9\-]{1,19}(?<!\-)$/i
    )
  end

  def http_url? : Bool
    return false if empty? || !url?
    uri = URI.parse(self)
    uri.scheme.nil? || uri.scheme.to_s.matches?(/^https?$/i)
  end

  def url? : Bool
    return false if empty?

    uri = URI.parse(self)
    valid = uri.host.nil? || uri.host.to_s.domain?

    valid &&= (uri.path.empty? ||
      uri.path.matches?(/^[a-z0-9\-\_\.\%\+\/]+$/i))

    valid &&= (uri.query.nil? ||
      uri.query.to_s.matches?(/^([a-z0-9\-\_\.\:\%\+\&\=\,\[\]]+)$/i))

    valid && (uri.fragment.nil? ||
      uri.fragment.to_s.matches?(/^[a-z0-9\-\_\.\%\+]+$/i))
  rescue
    false
  end

  def ip? : Bool
    ip4? || ip6?
  end

  def ip4? : Bool
    Socket::IPAddress.new(self, 0).ip4?
  rescue
    false
  end

  def ip6? : Bool
    Socket::IPAddress.new(self, 0).ip6?
  rescue
    false
  end
end

struct Socket::IPAddress
  def ip6? : Bool
    !!ip6?(address)
  end

  def ip4? : Bool
    !!ip4?(address)
  end
end

module Lucky
  abstract class Action
    include MailHelpers
  end

  class MessageEncryptor
    # Set default digest to `:sha256`
    def initialize(
      @secret : String,
      @cipher_algorithm = "aes-256-cbc",
      @digest = :sha256
    )
      previous_def
    end
  end

  class MessageVerifier
    # Set default digest to `:sha256`
    def initialize(@secret : String, @digest = :sha256)
      previous_def
    end
  end

  module RequestExpectations
    def send_json(status, expected : NamedTuple)
      SendJsonExpectation.new(status, expected.to_json)
    end
  end
end

module Avram
  class Attribute(T)
    def value!
      value.not_nil!
    end
  end

  abstract class Operation
    include MailHelpers
  end

  abstract class DeleteOperation(T)
    include MailHelpers

    def record!
      record.not_nil!
    end
  end

  abstract class SaveOperation(T)
    include MailHelpers

    def record!
      record.not_nil!
    end

    # Getting rid of default validations in Avram
    #
    # See https://github.com/luckyframework/lucky/discussions/1209#discussioncomment-46030
    #
    # All operations are expected to explicitly define any validations
    # needed
    def valid? : Bool
      # These validations must be ran after all `before_save` callbacks have completed
      # in the case that someone has set a required field in a `before_save`. If we run
      # this in a `before_save` ourselves, the ordering would cause this to be ran first.
      # validate_required *required_attributes
      custom_errors.empty? && attributes.all?(&.valid?)
    end
  end

  abstract class Factory
    # Mainly so we can pass symbols as args for enums, but you
    # can also pass any type the column's type adapter supports.
    macro setup_attribute_shortcuts(operation)
      {% for attribute in operation.resolve.constant(:COLUMN_ATTRIBUTES) %}
        def {{ attribute[:name] }}(value)
          operation.{{ attribute[:name] }}.value =
            {{ attribute[:type] }}.adapter.parse!(value)

          self
        end
      {% end %}
    end
  end

  module Validations
    def validate_email(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) unless value.email?
        end
      end
    end

    def validate_name(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          next if value.matches?(/^[a-z][a-z\-\s]*$/i)

          attribute.add_error(message)
        end
      end
    end

    def validate_username(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          next if value.matches?(/^[a-z\_][a-z0-9\_]*$/i)

          attribute.add_error(message)
        end
      end
    end

    def validate_slug(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          next if value.matches?(/^[a-z0-9\_][a-z0-9\_\-]*(?<!\-)$/i)

          attribute.add_error(message)
        end
      end
    end

    def validate_domain(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) unless value.domain?
        end
      end
    end

    def validate_domain_label(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          if value.matches?(/^[a-z0-9](?:[a-z0-9\-]*(?<!\.)\.?)*(?<![\.\-])$/i)
            next
          end

          attribute.add_error(message)
        end
      end
    end

    def validate_http_url(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) unless value.http_url?
        end
      end
    end

    def validate_url(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) unless value.url?
        end
      end
    end

    def validate_ip(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) unless value.ip?
        end
      end
    end

    def validate_ip4(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) unless value.ip4?
        end
      end
    end

    def validate_ip6(
      *attributes,
      message : Attribute::ErrorMessage = "is invalid"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) unless value.ip6?
        end
      end
    end

    def validate_positive_number(
      *attributes,
      message : Attribute::ErrorMessage = "must be positive"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) if value < 0
        end
      end
    end

    def validate_negative_number(
      *attributes,
      message : Attribute::ErrorMessage = "must be negative"
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          attribute.add_error(message) if value >= 0
        end
      end
    end

    def validate_primary_key(
      attribute,
      *,
      query : Queryable,
      message : Attribute::ErrorMessage = "does not exist"
    )
      attribute.value.try do |value|
        unless query.where(query.primary_key_name, value).first?
          attribute.add_error(message)
        end
      end
    end

    def validate_primary_key(
      attribute,
      *,
      query : Queryable.class,
      message : Attribute::ErrorMessage = "does not exist"
    )
      validate_primary_key(attribute, query: query.new, message: message)
    end

    def validate_not_pwned(
      *attributes,
      message : Attribute::ErrorMessage = "appears in a known data breach",
      remote_fail : Attribute::ErrorMessage? = "validation failed. Try again."
    )
      attributes.each do |attribute|
        attribute.value.try do |value|
          pwned = PwnedPasswords.pwned?(value)

          if pwned.nil?
            attribute.add_error(remote_fail.to_s) if remote_fail
          else
            attribute.add_error(message) if pwned
          end
        end
      end
    end
  end
end

# There's `avram_enum`, but that saves the enum value as
# `Int32` in the database. The problem is, enum member values are
# order-dependent -- the values change when the member ordering
# changes.
#
# Besides, you couldn't make sense of the numbers if you peeked
# into the database
#
# `__enum` saves enum members as `String` instead.
macro __enum(enum_name, &block)
  enum Raw{{ enum_name }}
    {{ block.body }}
  end

  struct {{ enum_name }}
    def self.adapter
      Lucky
    end

    def initialize(@raw : Raw{{ enum_name }})
    end

    def initialize(value : String)
      @raw = Raw{{ enum_name }}.parse(value)
    end

    def initialize(value : Symbol)
      @raw = initialize(value.to_s)
    end

    delegate :to_s, to: @raw
    forward_missing_to @raw

    def self.raw
      Raw{{ enum_name }}
    end

    module Lucky
      alias ColumnType = String

      include Avram::Type

      def self.criteria(query : T, column) forall T
        Criteria(T, {{ enum_name }}).new(query, column)
      end

      def parse(value : {{ enum_name }})
        SuccessfulCast({{ enum_name }}).new(value)
      end

      def parse(value : String)
        SuccessfulCast({{ enum_name }}).new {{ enum_name }}.new(value)
      rescue
        FailedCast.new
      end

      def parse(value : Symbol)
        parse value.to_s
      end

      def parse(value : Array)
        SuccessfulCast(Array({{ enum_name }})).new(value.map { |v| parse!(v) })
      end

      def to_db(value : {{ enum_name }})
        value.to_s
      end

      def to_db(values : Array({{ enum_name }}))
        PQ::Param.encode_array(values)
      end

      class Criteria(T, V) < String::Lucky::Criteria(T, V)
      end
    end
  end
end
