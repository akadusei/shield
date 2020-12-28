require "../../../spec_helper"

describe Shield::BearerLogins::Destroy do
  it "revokes bearer login" do
    email = "user@example.tld"
    password = "password4APASSWORD<"

    user = UserBox.create &.email(email)
      .password_digest(CryptoHelper.hash_bcrypt(password))

    bearer_login = CreateBearerLogin.create!(
      params(name: "secret token"),
      scopes: ["api.posts.index"],
      all_scopes: ["api.posts.update", "api.posts.index"],
      user_id: user.id
    )

    client = ApiClient.new
    client.browser_auth(user, password)

    response = client.exec(BearerLogins::Destroy.with(
      bearer_login_id: bearer_login.id
    ))

    response.headers["X-Bearer-Login-ID"]?.should eq(bearer_login.id.to_s)
  end

  it "requires logged in" do
    response = ApiClient.exec(BearerLogins::Destroy.with(
      bearer_login_id: 1_i64
    ))

    response.status.should eq(HTTP::Status::FOUND)
    response.headers["X-Logged-In"]?.should eq("false")
  end
end