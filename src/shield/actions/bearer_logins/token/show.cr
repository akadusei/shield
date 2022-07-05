module Shield::BearerLogins::Token::Show
  macro included
    skip :require_logged_out

    # get "/bearer-logins/token" do
    #   html ShowPage, bearer_login: bearer_login?, token: token?
    # end

    def bearer_login : BearerLogin
      bearer_login?.not_nil!
    end

    getter? bearer_login : BearerLogin? do
      token?.try { |token| BearerToken.new(token).bearer_login? }
    end

    def token : String
      token?.not_nil!
    end

    getter? token : String? do
      BearerTokenSession.new(session).bearer_token?
    end

    def authorize?(user : Shield::User) : Bool
      super || user.id == bearer_login?.try(&.user_id)
    end
  end
end