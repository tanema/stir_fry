# frozen_string_literal: true

module StirFry
  module Pages
    # Displays routes that are defined by the app. This is only enabled in development
    # and the route will not be define otherwise.
    class RouteList < Component
      attr_reader :application

      def initialize(application:) # :nodoc:
        super
        @application = application
      end
    end
  end
end

__END__
<section>
  <nav class="route-list">
    <p class="route-list__caption">{ "#{application.user_routes.length} registered routes" }</p>
    <ul class="route-list__items">
      {
        application.user_routes.map do |route| 
         <li class="route-list__item">
         <span class="route-list__verb" data-verb={route.verb}>{route.verb}</span>
           <code class="route-list__path">{route.path}</code>
           {route.description && <span class="route-list__description">{route.description}</span>}
         </li>
        end.join 
      }
    </ul>
  </nav>

  <nav class="route-list">
    <p class="route-list__caption">{application.framework_routes.length} framework routes, only in development</p>
    <ul class="route-list__items">
      {
        application.framework_routes.map do |route| 
         <li class="route-list__item">
           <span class="route-list__verb" data-verb={route.verb}>{route.verb}</span>
           <code class="route-list__path">{route.path}</code>
           {route.description && <span class="route-list__description">{route.description}</span>}
         </li>
        end.join 
      }
    </ul>
  </nav>
</section>
