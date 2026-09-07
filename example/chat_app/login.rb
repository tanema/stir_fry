# frozen_string_literal: true

module ChatApp
  # Chat is the root of the application, the home page.
  class Login < StirFry::Component
    def self.post(request:, response:, **)
      request.session[:user] = request.params["user"]&.gsub(/\W/, "")
      response.redirect("/")
    end
  end
end

__END__
<ChatApp.Layout>
  <div class="card">
    <form action="/login" method="POST" class="login-form">
      <label for='user'>User Name:</label>
      <input name="user" value="" />
      <input type="submit" value="GO!" />
    </form>
  </div>
</ChatApp.Layout>
