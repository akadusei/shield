require "../../../spec_helper"

describe Shield::CreatePassword do
  it "saves password" do
    password = "password12U-password"

    user = create_current_user!(
      email: "user@example.tld",
      password: password,
      password_confirmation: password
    )

    VerifyLogin.verify_bcrypt?(password, user.password_hash).should be_true
  end

  it "does not send password change notification" do
    password = "password1=Apassword"

    create_current_user(password_notify: "1") do |operation, user|
      PasswordChangeNotificationEmail
        .new(operation, user.not_nil!)
        .should_not(be_delivered)
    end
  end
end
