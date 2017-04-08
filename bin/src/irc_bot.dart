library irc_bot;

import 'dart:io';
import 'dart:async';
import 'dart:mirrors';

part 'irc/enums/message_type.dart';
part 'irc/enums/user_level.dart';
part 'irc/enums/messages.dart';

part 'irc/entities/irc_command.dart';
part 'irc/entities/irc_message.dart';
part 'irc/entities/sender.dart';

part 'irc/annotations/command_annotation.dart';

part 'irc/connection.dart';
part 'irc/plugin_base.dart';
part 'irc/user_container.dart';

part 'plugins/core.dart';
part 'plugins/echo.dart';
part 'plugins/ping.dart';
part 'plugins/invite.dart';
