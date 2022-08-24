require "../../../../../spec_helper"

describe Shield::Api::Oauth::Token::Verify do
  it "verifies OAuth access token" do
    scope = BearerScope.new(Api::CurrentUser::Show).to_s
    raw_login_token = "a1b2c3"
    raw_access_token = "d4e5f6"

    user = UserFactory.create

    bearer_login = BearerLoginFactory.create &.user_id(user.id)
      .token(raw_login_token)
      .scopes([BearerScope.new(Api::Oauth::Token::Verify).to_s])

    login_token = BearerLoginCredentials.new(raw_login_token, bearer_login.id)

    resource_owner = UserFactory.create &.email("resource@owner.com")
    UserOptionsFactory.create &.user_id(resource_owner.id)

    developer = UserFactory.create &.email("dev@app.com")
    oauth_client = OauthClientFactory.create &.user_id(developer.id)

    bearer_login_2 = BearerLoginFactory.create &.user_id(resource_owner.id)
      .token(raw_access_token)
      .oauth_client_id(oauth_client.id)
      .scopes([scope])

    access_token = BearerLoginCredentials.new(
      raw_access_token,
      bearer_login_2.id
    )

    client = ApiClient.new

    client.api_auth(login_token)

    response = client.exec(
      Api::Oauth::Token::Verify,
      token: access_token,
      scope: scope
    )

    response.should send_json(200, {active: true})
  end

  it "fails if token is invalid" do
    scope = BearerScope.new(Api::CurrentUser::Show).to_s
    raw_login_token = "a1b2c3"
    raw_access_token = "d4e5f6"

    user = UserFactory.create

    bearer_login = BearerLoginFactory.create &.user_id(user.id)
      .token(raw_login_token)
      .scopes([BearerScope.new(Api::Oauth::Token::Verify).to_s])

    login_token = BearerLoginCredentials.new(raw_login_token, bearer_login.id)

    resource_owner = UserFactory.create &.email("resource@owner.com")
    UserOptionsFactory.create &.user_id(resource_owner.id)

    developer = UserFactory.create &.email("dev@app.com")
    oauth_client = OauthClientFactory.create &.user_id(developer.id)

    bearer_login_2 = BearerLoginFactory.create &.user_id(resource_owner.id)
      .token(raw_access_token)
      .oauth_client_id(oauth_client.id)
      .scopes([scope])
      .inactive_at(Time.utc)

    access_token = BearerLoginCredentials.new(
      raw_access_token,
      bearer_login_2.id
    )

    client = ApiClient.new

    client.api_auth(login_token)

    response = client.exec(
      Api::Oauth::Token::Verify,
      token: access_token,
      scope: scope
    )

    response.should send_json(200, {active: false})
  end

  it "requires logged in" do
    response = ApiClient.exec(Api::Oauth::Token::Verify, token: "a1b2c3")

    response.should send_json(401, logged_in: false)
  end
end
