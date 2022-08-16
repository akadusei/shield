module Shield::OauthHelpers
  macro included
    def oauth_redirect_uri(**params)
      oauth_redirect_uri?(**params).not_nil!
    end

    def oauth_redirect_uri?(**params)
      oauth_client?.try do |oauth_client|
        uri = URI.parse(oauth_client.redirect_uri)
        query_params = uri.query_params
        params.each { |name, value| query_params.add(name.to_s, value.to_s) }
        uri.query_params = query_params
        uri
      end
    end

    def oauth_client_id
      oauth_client_id?.not_nil!
    end

    def oauth_client_id?
      OauthClient::PrimaryKeyType.adapter.parse(client_id).value
    end

    def oauth_client : OauthClient
      oauth_client?.not_nil!
    end

    getter? oauth_client : OauthClient? do
      oauth_client_id?.try { |id| OauthClientQuery.new.id(id).first? }
    end
  end
end
