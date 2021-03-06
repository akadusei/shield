abstract class BaseModel < Avram::Model
  include Shield::Model
end

abstract class BrowserAction < Lucky::Action
  include Shield::BrowserAction
end

abstract class ApiAction < Lucky::Action
  include Shield::ApiAction
end

struct PageUrlSession
  include Shield::PageUrlSession
end

struct ReturnUrlSession
  include Shield::ReturnUrlSession
end

struct BearerToken
  include Shield::BearerToken
end

struct BearerScope
  include Shield::BearerScope
end

struct BcryptHash
  include Shield::BcryptHash
end

struct Sha256Hash
  include Shield::Sha256Hash
end

struct PwnedPasswords
  include Shield::PwnedPasswords
end
