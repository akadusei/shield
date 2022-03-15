module Shield::Api::EmailConfirmations::Index
  macro included
    skip :require_logged_out

    # param page : Int32 = 1

    # get "/email-confirmations" do
    #   json EmailConfirmationSerializer.new(
    #     email_confirmations: email_confirmations,
    #     pages: pages
    #   )
    # end

    def pages
      paginated_email_confirmations[0]
    end

    getter email_confirmations : Array(EmailConfirmation) do
      paginated_email_confirmations[1].results
    end

    private getter paginated_email_confirmations : Tuple(
      Lucky::Paginator,
      EmailConfirmationQuery
    ) do
      paginate EmailConfirmationQuery.new
        .is_active
        .preload_user
        .active_at.desc_order
    end
  end
end
