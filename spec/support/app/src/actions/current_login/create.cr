class CurrentLogin::Create < BrowserAction
  include Shield::CurrentLogin::Create

  post "/log-in" do
    run_operation
  end

  def do_run_operation_succeeded(operation, login)
    response.headers["X-Login-ID"] = current_login!.id.to_s
    response.headers["X-Login-Token"] = operation.token
    response.headers["X-User-ID"] = current_user!.id.to_s
    previous_def
  end

  # To skip cache
  def current_user : User?
    current_login.try &.user!
  end

  # To skip cache
  def current_login : Login?
    LoginSession.new(session).verify
  end

  def remote_ip : Socket::IPAddress?
    Socket::IPAddress.new("128.0.0.2", 5000)
  end
end
