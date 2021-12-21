module Shield::RegisterUser
  macro included
    permit_columns :email

    attribute password : String

    include Shield::SetPasswordDigestFromPassword
    include Shield::ValidateUser
  end
end
