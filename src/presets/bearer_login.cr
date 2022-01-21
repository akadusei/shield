{% skip_file unless Avram::Model.all_subclasses
  .map(&.stringify)
  .includes?("BearerLogin")
%}

class User < BaseModel
  include Shield::HasManyBearerLogins
end

class BearerLoginQuery < BearerLogin::BaseQuery
  include Shield::BearerLoginQuery
end

class CreateBearerLogin < BearerLogin::SaveOperation
  include Shield::CreateBearerLogin
end

class RevokeBearerLogin < BearerLogin::SaveOperation
  include Shield::RevokeBearerLogin
end

class DeleteBearerLogin < BearerLogin::DeleteOperation
  include Shield::DeleteBearerLogin
end

abstract class ApiAction < Lucky::Action
  include Shield::Api::BearerLoginHelpers
  include Shield::Api::BearerLoginPipes
end

struct BearerLoginHeaders
  include Shield::BearerLoginHeaders
end
