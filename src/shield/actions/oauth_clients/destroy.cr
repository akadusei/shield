module Shield::OauthClients::Destroy
  macro included
    skip :require_logged_out

    # delete "/oauth/clients/:oauth_client_id" do
    #   run_operation
    # end

    def run_operation
      DeactivateOauthClient.update(
        oauth_client
      ) do |operation, updated_oauth_client|
        if operation.saved?
          do_run_operation_succeeded(operation, updated_oauth_client)
        else
          response.status_code = 400
          do_run_operation_failed(operation)
        end
      end
    end

    def do_run_operation_succeeded(operation, oauth_client)
      flash.success = Rex.t(:"action.oauth_client.destroy.success")
      redirect to: Index
    end

    def do_run_operation_failed(operation)
      flash.failure = Rex.t(:"action.oauth_client.destroy.failure")
      redirect_back fallback: Index
    end

    getter oauth_client : OauthClient do
      OauthClientQuery.find(oauth_client_id)
    end

    def authorize?(user : Shield::User) : Bool
      super || user.id == oauth_client.user_id
    end
  end
end
