module Shield::Api::CurrentLogins::Destroy
  macro included
    skip :require_logged_out

    # delete "/account/logins" do
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

    {% if Avram::Model.all_subclasses
      .map(&.stringify)
      .includes?("BearerLogin") %}

      def user
        current_user_or_bearer
      end
    {% else %}
      def user
        current_user
      end
    {% end %}

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