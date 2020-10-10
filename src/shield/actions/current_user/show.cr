module Shield::CurrentUser::Show
  macro included
    skip :require_logged_out

    # get "/account" do
    #   html ShowPage, user: user
    # end

    def user
      current_user!
    end

    def authorize?(user : User) : Bool
      user.id == current_user.try &.id
    end
  end
end
