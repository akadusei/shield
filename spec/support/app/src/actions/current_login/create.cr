class CurrentLogin::Create < BrowserAction
  include Shield::CurrentLogin::Create

  post "/log-in" do
    run_operation
  end

  def do_run_operation_succeeded(operation, login)
    json({
      login: login.id,
      session: 1,
      current_login: current_login!.id,
      current_user: current_user!.id,
      login_token: operation.token
    })
  end

  def do_run_operation_failed(operation)
    json({errors: operation.errors})
  end

  def remote_ip : Socket::IPAddress?
    Socket::IPAddress.new("128.0.0.2", 5000)
  end
end
