module Shield::Api::Users::Show
  macro included
    skip :require_logged_out

    # get "/users/:user_id" do
    #   json({
    #     status: "success",
    #     data: {user: UserSerializer.new(user)}
    #   })
    # end

    @[Memoize]
    def user : User
      UserQuery.find(user_id)
    end
  end
end
