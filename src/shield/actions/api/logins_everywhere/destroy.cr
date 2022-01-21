module Shield::Api::LoginsEverywhere::Destroy
  macro included
    skip :require_logged_out

    # delete "/login/all" do
    #   run_operation
    # end

    def run_operation
      LogOutEverywhere.update(
        user,
        current_login: current_login?
      ) do |operation, updated_user|
        if operation.saved?
          do_run_operation_succeeded(operation, updated_user)
        else
          do_run_operation_failed(operation)
        end
      end
    end

    def user
      current_user_or_bearer
    end

    def do_run_operation_succeeded(operation, user)
      json({
        status: "success",
        message: Rex.t(:"action.login_everywhere.destroy.success"),
        data: {user: UserSerializer.new(user)}
      })
    end

    def do_run_operation_failed(operation)
      json({
        status: "failure",
        message: Rex.t(:"action.login_everywhere.destroy.failure"),
        data: {errors: operation.errors}
      })
    end

    def authorize?(user : Shield::User) : Bool
      user.id == self.user.id
    end
  end
end
