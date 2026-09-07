# frozen_string_literal: true

# Chat is the root of the application, the home page.
class Login < StirFry::Component
  def self.post(request:, response:, **)
    request.session[:user] = request.params["user"]&.gsub(/\W/, "")
    response.redirect("/")
  end
end

__END__
<Layout>
  <div class="card">
    <form action="/login" method="POST" class="login-form">
      <label for='user'>User Name:</label>
      <input name="user" value="" />
      <input type="submit" value="GO!" />
    </form>
  </div>
</Layout>
