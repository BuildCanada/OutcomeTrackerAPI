Feedjira.configure do |config|
  config.parsers = [
    Feedjira::Parser::ITunesRSS,
    Feedjira::Parser::AtomYoutube,
    Feedjira::Parser::JSONFeed,
    Feedjira::Parser::AtomFeedBurner,
    Feedjira::Parser::Atom,
    Feedjira::Parser::RSSFeedBurner,
    Feedjira::Parser::RSS
  ]
end
