class Api::Oauth::Token::Create < ApiAction
  include Shield::Api::Oauth::Token::Create

  skip :pin_login_to_ip_address
  skip :oauth_validate_client_id
  # skip :oauth_handle_errors
  skip :oauth_check_duplicate_params
  skip :oauth_require_access_token_params
  skip :oauth_validate_redirect_uri
  skip :oauth_validate_grant_type
  skip :oauth_validate_code
  skip :oauth_check_multiple_client_auth
  skip :oauth_validate_client_secret

  post "/oauth/token" do
    run_operation
  end
end