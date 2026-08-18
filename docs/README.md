# Nextrb

## Installation

## Usage

## Development
After checking out the repo, run `bundle install` to install dependencies. Then, run 
`rake test` to run the tests. You can also run `rake console` for an interactive 
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To 
release a new version, update the version number in `version.rb`, and then 
run `bundle exec rake release`, which will create a git tag for the version, push 
git commits and the created tag, and push the `.gem` file to 
[rubygems.org](https://rubygems.org).

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/tanema/nextrb. 
This project is intended to be a safe, welcoming space for collaboration, and contributors 
are expected to adhere to the [code of conduct](docs/CODE_OF_CONDUCT.md).

## License
The gem is available as open source under the terms of the 
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
Everyone interacting in the Nextrb project's codebases, issue trackers, chat 
rooms and mailing lists is expected to follow the 
[code of conduct](docs/CODE_OF_CONDUCT.md).

## Acknowledgment 
These are the projects that I took both inspiration and code chunks from. Since I 
wanted an interface a lot like Sinatra, I used their codebase heavily for routing.
Also since I wanted a reactjs markdown style, I used rbexy initially but then 
ended up re-writing a lot of it to remove all rails integrations and simplify.

- [Sinatra](https://github.com/sinatra/sinatra/)
- [Rbexy](https://github.com/patbenatar/rbexy)
- [Rack](https://github.com/rack/rack)
