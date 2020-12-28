require "../../../../spec_helper"

describe Shield::Api::EmailConfirmationCurrentUser::Update do
  it "updates user" do
    email = "user@example.tld"
    password = "password4APASSWORD<"
    new_level = User::Level.new(:author)

    user = UserBox.create &.email(email)
      .level(User::Level.new(:admin))
      .password_digest(CryptoHelper.hash_bcrypt(password))

    client = ApiClient.new
    client.api_auth(user, password)

    response = client.exec(Api::EmailConfirmationCurrentUser::Update, user: {
      level: new_level.to_s
    })

    response.should send_json(200, {status: "success"})
    user.reload.level.should eq(new_level)
  end

  it "requires logged in" do
    response = ApiClient.exec(Api::EmailConfirmationCurrentUser::Update, user: {
      level: User::Level.new(:author).to_s
    })

    response.should send_json(401, logged_in: false)
  end
end