import 'package:share_plus/share_plus.dart';

class ShareHelper {
  ShareHelper._();

  static Future<void> shareDua(String text) async {
    await Share.share(text);
  }
}