require "../../../spec_helper"

describe Shield::ConfirmDelete do
  it "confirms deletion" do
    user = UserFactory.create
    UserOptionsFactory.create &.user_id(user.id)
    password_reset = PasswordResetFactory.create &.user_id(user.id)

    DeletePasswordReset.destroy(
      password_reset,
      params(confirmation: true)
    ) do |operation, deleted_password_reset|
      operation.deleted?.should be_true

      PasswordResetQuery.new.id(password_reset.id).first?.should be_nil
    end
  end

  it "denies deletion" do
    user = UserFactory.create
    UserOptionsFactory.create &.user_id(user.id)
    password_reset = PasswordResetFactory.create &.user_id(user.id)

    DeletePasswordReset.destroy(
      password_reset,
      params(confirmation: false)
    ) do |operation, deleted_password_reset|
      operation.deleted?.should be_false

      PasswordResetQuery.new
        .id(password_reset.id)
        .first?
        .should(be_a PasswordReset)
    end
  end
end
