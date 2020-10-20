require "../../../spec_helper"

describe Shield::Api::AuthenticationPipes do
  describe "#require_logged_in" do
    it "allows logins with regular passwords" do
      email = "user@example.tld"
      password = "password4APASSWORD<"

      user = UserBox.create &.email(email)
        .password_digest(CryptoHelper.hash_bcrypt(password))

      LogUserIn.create(
        params(email: email, password: password),
        remote_ip: Socket::IPAddress.new("128.0.0.2", 5000)
      ) do |operation, login|
        login = login.not_nil!

        bearer_header = LoginHelper.bearer_header(login, operation)

        client = ApiClient.new
        client.headers("Authorization": bearer_header)
        response = client.exec(Api::Posts::Index)

        response.should send_json(200, current_user: user.id)
      end
    end

    it "allows logins with user-generated bearer tokens" do
      email = "user@example.tld"
      password = "password4APASSWORD<"

      user = UserBox.create &.email(email)
        .password_digest(CryptoHelper.hash_bcrypt(password))

      CreateBearerLogin.create(
        params(name: "secret token"),
        scopes: ["api.posts.index"],
        all_scopes: ["api.posts.update", "api.posts.index"],
        user_id: user.id
      ) do |operation, bearer_login|
        bearer_login = bearer_login.not_nil!

        bearer_header = BearerLoginHelper.bearer_header(bearer_login, operation)

        client = ApiClient.new
        client.headers("Authorization": bearer_header)
        response = client.exec(Api::Posts::Index)

        response.should send_json(200, current_bearer_user: user.id)
      end
    end

    it "requires logged in" do
      response = ApiClient.exec(Api::Posts::Index)

      response.headers["WWW-Authenticate"]?.should_not be_nil
      response.should send_json(401, logged_in: false)
    end
  end

  describe "#require_logged_out" do
    it "rejects logins with regular passwords" do
      email = "user@example.tld"
      password = "password4APASSWORD<"

      UserBox.create &.email(email)
        .password_digest(CryptoHelper.hash_bcrypt(password))

      LogUserIn.create(
        params(email: email, password: password),
        remote_ip: Socket::IPAddress.new("129.0.0.5", 5555)
      ) do |operation, login|
        login = login.not_nil!

        bearer_header = LoginHelper.bearer_header(login, operation)

        client = ApiClient.new
        client.headers("Authorization": bearer_header)
        response = client.exec(Api::Posts::New)

        response.should send_json(200, logged_in: true)
      end
    end

    it "rejects logins with user-generated bearer tokens" do
      email = "user@example.tld"
      password = "password4APASSWORD<"

      user = UserBox.create &.email(email)
        .password_digest(CryptoHelper.hash_bcrypt(password))

      CreateBearerLogin.create(
        params(name: "secret token"),
        scopes: ["api.posts.new"],
        all_scopes: ["api.posts.new", "api.posts.index"],
        user_id: user.id
      ) do |operation, bearer_login|
        bearer_login = bearer_login.not_nil!

        bearer_header = BearerLoginHelper.bearer_header(bearer_login, operation)

        client = ApiClient.new
        client.headers("Authorization": bearer_header)
        response = client.exec(Api::Posts::New)

        response.should send_json(200, logged_in: true)
      end
    end
  end

  describe "#pin_login_to_ip_address" do
    context "for logins with regular passwords" do
      it "accepts login from same IP" do
        email = "user@example.tld"
        password = "password4APASSWORD<"

        user = UserBox.create &.email(email)
          .level(User::Level.new :admin)
          .password_digest(CryptoHelper.hash_bcrypt(password))

        LogUserIn.create(
          params(email: email, password: password),
          remote_ip: Socket::IPAddress.new("128.0.0.2", 5000)
        ) do |operation, login|
          login = login.not_nil!

          bearer_header = LoginHelper.bearer_header(login, operation)

          client = ApiClient.new
          client.headers("Authorization": bearer_header)
          response = client.exec(Api::Posts::Index)

          response.should send_json(200, current_user: user.id)
        end
      end

      it "rejects login from different IP" do
        email = "user@example.tld"
        password = "password4APASSWORD<"

        user = UserBox.create &.email(email)
          .level(User::Level.new :admin)
          .password_digest(CryptoHelper.hash_bcrypt(password))

        LogUserIn.create(
          params(email: email, password: password),
          remote_ip: Socket::IPAddress.new("1.2.3.4", 5)
        ) do |operation, login|
          login = login.not_nil!

          bearer_header = LoginHelper.bearer_header(login, operation)

          client = ApiClient.new
          client.headers("Authorization": bearer_header)
          response = client.exec(Api::Posts::Index)

          response.should send_json(403, ip_address_changed: true)
        end
      end
    end
  end
end