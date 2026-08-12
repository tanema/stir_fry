class App::Page < Nextrb::Component
  def name
    "tim"
  end
end


__END__

<html>
  <head></head>
  <body>
    <Name name={name}/>
  </body>
</html>
