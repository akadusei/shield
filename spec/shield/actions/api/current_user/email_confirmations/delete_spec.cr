require "../../../../../spec_helper"

describe Shield::Api::CurrentUser::EmailConfirmations::Delete do
  it "deletes email confirmations" do
    email = "user@example.tld"
    password = "password4APASSWORD<"
    ip_address = Socket::IPAddress.new("128.0.0.2", 5000)

    client = ApiClient.new
    client.api_auth(email, password, ip_address)

    response = client.exec(Api::CurrentUser::EmailConfirmations::Delete)

    response.should send_json(200, {
      message: "action.current_user.email_confirmation.destroy.success"
    })
  end

  it "requires logged in" do
    response = ApiClient.exec(Api::CurrentUser::EmailConfirmations::Delete)

    response.should send_json(401, logged_in: false)
  end
end
