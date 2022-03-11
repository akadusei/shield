class Api::Users::Show < ApiAction
  include Shield::Api::Users::Show

  skip :pin_login_to_ip_address
  skip :check_authorization

  get "/users/:user_id" do
    json ItemResponse.new(user: user)
  end
end
