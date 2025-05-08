import 'package:platform/platform.dart';

class PlatformUtils {
  static bool get isMobile =>
      const LocalPlatform().isAndroid || const LocalPlatform().isIOS;

  static bool get isDesktop =>
      const LocalPlatform().isWindows ||
      const LocalPlatform().isLinux ||
      const LocalPlatform().isMacOS;
}
