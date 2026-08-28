module Nextrb
  module Common
    def app_env = Nextrb.env
    def development? = %i[development dev].include?(app_env)
    def test? = app_env == :test
    def production? = %i[production prod].include?(app_env)
    def logger = Nextrb.logger
  end
end
