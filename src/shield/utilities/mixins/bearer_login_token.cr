module Shield::BearerLoginToken
  macro included
    def bearer_login : BearerLogin
      bearer_login?.not_nil!
    end

    getter? bearer_login : BearerLogin? do
      BearerLoginQuery.new.id(id).first?
    end
  end
end
