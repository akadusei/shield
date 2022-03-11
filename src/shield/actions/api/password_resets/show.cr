module Shield::Api::PasswordResets::Show
  macro included
    skip :require_logged_in

    # get "/password-resets/:token" do
    #   json ItemResponse.new(password_reset: password_reset)
    # end

    def password_reset
      password_reset?.not_nil!
    end

    getter? password_reset : PasswordReset? do
      PasswordResetParams.new(params).password_reset?
    end
  end
end
