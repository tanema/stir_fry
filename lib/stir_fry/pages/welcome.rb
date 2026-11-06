# frozen_string_literal: true

module StirFry
  module Pages
    # Welcome is the default landing page for when the developer has not defined
    # a root route yet.
    class Welcome < Component; end
  end
end

__END__
<StirFry.Pages.Layout>
  <main class="welcome">
    <div class="welcome__hero">
      <p class="welcome__logo">🥡</p>
      <h1 class="welcome__title">Welcome to your StirFry app!</h1>
      <p class="welcome__tagline">Lets get cooking!</p>
    </div>

    <ul class="welcome__links">
      <li><a class="welcome__link" href="https://github.com/tanema/stir_fry/wiki/Create-your-first-Stir-Fry!">🏗️ Quickstart</a></li>
      <li><a class="welcome__link" href="https://timanema.com/stir_fry/">📄 Documentation</a></li>
      <li><a class="welcome__link" href="https://github.com/tanema/stir_fry/tree/main/example">🔎 Examples</a></li>
      <li><a class="welcome__link" href="/stir_fry/routes">🗺️ Your routes</a></li>
    </ul>

    <h2 class="welcome__subtitle">Get started by adding a route to your app</h2>

    <pre class="welcome__code"><code># frozen_string_literal: true

require "stir_fry"

class App < StirFry::App # :nodoc:
  get "/" do |name:, response:, **|
    response.text("Hello World!")
  end
end

run App
</code></pre>

    <footer class="welcome__versions">
      <p>
        <strong>StirFry:</strong><a href="https://rubygems.org/gems/stir_fry"><img src="https://badge.fury.io/rb/stir_fry.svg?icon=si%3Arubygems" alt="StirFry gem version"></a>
        <strong>RBXrb:</strong><a href="https://rubygems.org/gems/rbxrb"><img src="https://badge.fury.io/rb/rbxrb.svg?icon=si%3Arubygems" alt="RBXrb gem version"></a>
        <strong>Ruby version:</strong> {RUBY_VERSION}
      </p>
    </footer>
  </main>
</StirFry.Pages.Layout>
