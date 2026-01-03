import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pilipala/services/loggeer.dart';

final logger = getLogger();
const bool isDebug = true; // 控制是否输出调试日志

class SmartDialogUtil {
  static showToast(String msg, {bool? printToConsole}) {
    final shouldPrint = printToConsole ?? true;
    if (shouldPrint && isDebug) {
      logger.d('[SmartDialog Toast] $msg');
    }
    SmartDialog.showToast(msg);
  }

  static showNotify({
    required String msg,
    NotifyType notifyType = NotifyType.warning,
    bool? printToConsole,
  }) {
    final shouldPrint = printToConsole ?? true;
    if (shouldPrint && isDebug) {
      logger.w('[SmartDialog Notify] $msg');
    }
    SmartDialog.showNotify(msg: msg, notifyType: notifyType);
  }

  // 其他SmartDialog方法的封装...
}
