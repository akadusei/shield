require "../../../spec_helper"

describe Shield::PasswordResets::Update do
  it "resets password" do
    email = "user@example.tld"
    password = "password4APASSWORD<"
    new_password = "assword4APASSWOR<"

    user = UserBox.create &.email(email)
      .password_digest(CryptoHelper.hash_bcrypt(password))

    StartPasswordReset.create(
      params(email: email),
      remote_ip: Socket::IPAddress.new("129.0.0.5", 6000)
    ) do |operation, password_reset|
      password_reset = password_reset.not_nil!

      session = Lucky::Session.new
      PasswordResetSession.new(session).set(password_reset, operation)

      client = ApiClient.new
      client.set_cookie_from_session(session)

      response = client.exec(PasswordResets::Update, user: {
        password: new_password
      })

      CryptoHelper.verify_bcrypt?(new_password, user.reload.password_digest)
        .should(be_true)
    end
  end

  it "rejects invalid password reset token" do
    email = "user@example.tld"
    password = "password4APASSWORD<"
    new_password = "assword4APASSWOR<"

    UserBox.create &.email(email)
      .password_digest(CryptoHelper.hash_bcrypt(password))

    password_reset = StartPasswordReset.create!(
      params(email: email),
      remote_ip: Socket::IPAddress.new("129.0.0.5", 6000)
    )

    session = Lucky::Session.new
    PasswordResetSession.new(session).set(password_reset.id, "abcdef")

    client = ApiClient.new
    client.set_cookie_from_session(session)

    response = client.exec(PasswordResets::Update, user: {
      password: new_password
    })

    response.status.should eq(HTTP::Status::FOUND)
    response.headers["X-Password-Reset-Status"]?.should eq("failure")
  end

  it "requires logged out" do
    email = "user@example.tld"
    password = "password4APASSWORD<"
    new_password = "assword4APASSWOR<"

    client = ApiClient.new
    client.browser_auth(email, password)

    response = client.exec(PasswordResets::Update, user: {
      password: new_password
    })

    response.status.should eq(HTTP::Status::FOUND)
    response.headers["X-Logged-In"].should eq("true")
  end
end