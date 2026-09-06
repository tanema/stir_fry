# frozen_string_literal: true

require "json"

module ChatApp
  # Chat is the root of the application, the home page.
  class Chat < Nextrb::Component
    def self.get(request:, response:, **)
      user = request.session[:user]
      return response.redirect("/login") if user.nil?

      response.render(new(user: user))
    end

    def self.post(request:, response:, **)
      payload = JSON.parse(request.body.read)
      ConnectionManager.queue_message("#{request.session[:user]}: #{payload["msg"]}")
      response.status(204)
    end
  end
end

__END__
<ChatApp.Layout>
  <div class="card">
    <pre id='chat' class="chat-messages"></pre>
    <form id='new_message' class="chat-form"><input id='msg' placeholder='type message here...' /></form>
  </div>
  <script src="/chat.js"></script>
</ChatApp.Layout>
