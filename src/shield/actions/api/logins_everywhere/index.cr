module Shield::Api::LoginsEverywhere::Index
  macro included
    skip :require_logged_out

    # param page : Int32 = 1

    # get "/login/all" do
    #   json({
    #     status: "success",
    #     data: {logins: LoginSerializer.for_collection(logins)},
    #     pages: {
    #       current: page,
    #       total: pages.total
    #     }
    #   })
    # end

    def pages
      paginated_logins[0]
    end

    getter logins : Array(Login) do
      paginated_logins[1].results
    end

    private getter paginated_logins : Tuple(Lucky::Paginator, LoginQuery) do
      paginate LoginQuery.new.user_id(user.id).is_active.active_at.desc_order
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

    def authorize?(user : Shield::User) : Bool
      user.id == self.user.id
    end
  end
end