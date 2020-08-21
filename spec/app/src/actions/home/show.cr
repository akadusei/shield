class Home::Show < ApiAction
  skip :require_logged_in
  skip :require_logged_out

  get "/show" do
    redirect_back fallback: Home::Index
  end
end
