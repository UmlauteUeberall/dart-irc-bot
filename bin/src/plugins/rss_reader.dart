part of irc_bot;

class RssReaderPlugin extends IrcPluginBase {
  List<FeedInfo> _feeds = new List<FeedInfo>();
  JsonConfig _config;
  Timer _timer;

  String _configKey;

  @override
  Future<Null> register() async {
    _configKey = _server._host;

    _config = await JsonConfig.fromPath("rss_reader.json");
    var feedMap = _config.get(_configKey);

    if (feedMap != null) {
      (feedMap as List<Map<String, String>>)
          .forEach((map) => _feeds.add(new FeedInfo.fromMap(map)));
    } else {
      _config.set(_configKey, _feeds.map((f) => f.toMap()).toList());
      await _config.save();
    }

    _timer =
        new Timer.periodic(new Duration(seconds: 10), (timer) => checkFeeds());
  }

  Future<bool> _addFeed(FeedInfo feedInfo) async {
    var existingFeed =
        _feeds.firstWhere((f) => f.title == feedInfo.title, orElse: () => null);

    if (existingFeed == null) {
      _feeds.add(feedInfo);
      _config.set(_configKey, _feeds.map((f) => f.toMap()).toList());
      await _config.save();

      return true;
    }

    return false;
  }

  Future<bool> _deleteFeed(String title) async {
    var existingFeed =
        _feeds.firstWhere((f) => f.title == title, orElse: () => null);

    if (existingFeed != null) {
      _feeds.remove(existingFeed);
      _config.set(_configKey, _feeds.map((f) => f.toMap()).toList());
      await _config.save();

      return true;
    }

    return false;
  }

  void checkFeeds() {
    var feeds = _feeds.toList();

    feeds.forEach((feedInfo) async {
      try {
        var feed = await Feed.fromUrl(feedInfo.url);

        if (feedInfo.items.isNotEmpty) {
          var newItems = feedInfo.getNewItems(feed.items);

          if (newItems.isNotEmpty) {
            newItems.forEach((item) async {
              var url = await GoogleUrlShortenerPlugin.shortenUrl(item.url);
              _server.sendMessage(
                  feedInfo.channel,
                  _T(Messages.RSS_FEED_OUTPUT,
                      [feedInfo.title, item.title, url]));
            });
          }
        } else {
          feedInfo.initializeWithItems(feed.items);
        }
      } catch (error) {
        _server.sendMessage(feedInfo.channel,
            _T(Messages.RSS_FEED_ERROR, [feedInfo.title, error]));
      }
    });
  }

  @Command("rssadd", const ["title", "url"])
  bool onAddRssFeed(IrcCommand command) {
    var channel = command.originalMessage.returnTo;
    var title = command.arguments.first;
    var url = command.arguments.last;

    var feedInfo = new FeedInfo(channel, title, url);
    _addFeed(feedInfo).then((success) {
      if (success) {
        _server.sendMessage(
            channel, _T(Messages.RSS_FEED_ADD_SUCCESS, [feedInfo.title]));
      } else {
        _server.sendMessage(channel, _T(Messages.RSS_FEED_ALREADY_EXISTS));
      }
    });
  }

  @Command("rssdel", const ["title"])
  bool onDeleteRssFeed(IrcCommand command) {
    var channel = command.originalMessage.returnTo;
    var title = command.arguments.first;

    _deleteFeed(title).then((success) {
      if (success) {
        _server.sendMessage(
            channel, _T(Messages.RSS_FEED_DELETE_SUCCESS, [title]));
      } else {
        _server.sendMessage(channel, _T(Messages.RSS_FEED_NON_EXISTANT));
      }
    });
  }
}