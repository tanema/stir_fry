# frozen_string_literal: true

require "json"

module ChatApp
  # https://develclan.com/ruby-streaming-bodies-sse-websockets-rack/
  # Thread.new { }
  # Thread::Queue is a thread safe communication method.
  # queue = Thread::Queue.new
  # queue << message
  # stream.write("data: #{queue.pop}\n\n")
  #
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
  <pre id='chat'></pre>
  <form id='new_message'><input id='msg' placeholder='type message here...' /></form>
  <script src="/chat.js"></script>
</ChatApp.Layout>
