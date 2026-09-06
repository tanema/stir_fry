# frozen_string_literal: true

module ChatApp
  # Chat is the root of the application, the home page.
  class Login < Nextrb::Component
    def self.post(request:, response:, **)
      request.session[:user] = request.params["user"]&.gsub(/\W/, "")
      response.redirect("/")
    end
  end
end

__END__
<ChatApp.Layout>
  <form action="/login" method="POST">
    <label for='user'>User Name:</label>
    <input name="user" value="" />
    <input type="submit" value="GO!" />
  </form>
</ChatApp.Layout>
