# frozen_string_literal: true

module Nextrb
  # Pages contains built in pages for errors
  module Pages
    autoload :Layout, "nextrb/pages/layout"
    autoload :NotFound, "nextrb/pages/not_found"
    autoload :BadRequest, "nextrb/pages/bad_request"
    autoload :Unauthorized, "nextrb/pages/unauthorized"
    autoload :InternalError, "nextrb/pages/internal_error"
  end
end
