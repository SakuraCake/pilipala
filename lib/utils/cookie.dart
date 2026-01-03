import 'dart:convert';

import 'package:universal_platform/universal_platform.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:pilipala/http/constants.dart';
import 'package:pilipala/http/init.dart';
import 'package:pilipala/services/loggeer.dart';

// 导入Cookie类
import 'package:webview_cookie_manager/webview_cookie_manager.dart' if (dart.library.html) '';

// 仅在Windows平台导入webview_windows
import 'package:webview_windows/webview_windows.dart' as webview_windows if (dart.library.html) '';

final logger = getLogger();
const bool isDebug = true; // 控制是否输出调试日志

class SetCookie {
  static webview_windows.WebviewController? _windowsWebViewController;
  
  // 设置Windows平台的WebviewController
  static void setWindowsWebViewController(webview_windows.WebviewController controller) {
    _windowsWebViewController = controller;
  }

  static onSet() async {
    if (UniversalPlatform.isWindows) {
      // Windows平台处理
      await _handleWindowsCookies();
    } else {
      // 非Windows平台处理
      await _handleNonWindowsCookies();
    }
  }
  
  // 处理非Windows平台的cookies
  static _handleNonWindowsCookies() async {
    if (isDebug) logger.d('[Cookie] 开始获取非Windows平台cookies...');
    var cookies = await WebviewCookieManager().getCookies(HttpString.baseUrl);
    if (isDebug) logger.d('[Cookie] 获取到baseUrl cookies: $cookies');
    await Request.cookieManager.cookieJar
        .saveFromResponse(Uri.parse(HttpString.baseUrl), cookies);
    var cookieString = 
        cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    Request.dio.options.headers['cookie'] = cookieString;
    if (isDebug) logger.d('[Cookie] 设置Dio cookie: $cookieString');

    cookies = await WebviewCookieManager().getCookies(HttpString.apiBaseUrl);
    if (isDebug) logger.d('[Cookie] 获取到apiBaseUrl cookies: $cookies');
    await Request.cookieManager.cookieJar
        .saveFromResponse(Uri.parse(HttpString.apiBaseUrl), cookies);

    cookies = await WebviewCookieManager().getCookies(HttpString.tUrl);
    if (isDebug) logger.d('[Cookie] 获取到tUrl cookies: $cookies');
    await Request.cookieManager.cookieJar
        .saveFromResponse(Uri.parse(HttpString.tUrl), cookies);
    if (isDebug) logger.d('[Cookie] 非Windows平台cookies处理完成');
  }
  
  // 处理Windows平台的cookies
  static _handleWindowsCookies() async {
    if (_windowsWebViewController == null) {
      if (isDebug) logger.w('[Cookie] Windows WebView Controller 未初始化');
      return;
    }
    
    try {
      // 从Windows WebView获取所有cookies
      if (isDebug) logger.d('[Cookie] 开始获取Windows WebView cookies...');
      final cookiesJson = await _windowsWebViewController!.executeScript("JSON.stringify(document.cookie.split('; ').map(cookie => { const [name, ...value] = cookie.split('='); return { name: decodeURIComponent(name), value: decodeURIComponent(value.join('=')) }; }));");
      
      // 解析cookies
      final List<dynamic> cookiesList = jsonDecode(cookiesJson);
      if (isDebug) logger.d('[Cookie] 获取到Windows cookies: $cookiesList');
      
      // 构建cookie字符串
      var cookieString = '';
      if (cookiesList.isNotEmpty) {
        cookieString = cookiesList.map((cookieMap) {
          final name = cookieMap['name'] as String?;
          final value = cookieMap['value'] as String?;
          if (name != null && value != null) {
            return '$name=$value';
          }
          return '';
        }).where((cookie) => cookie.isNotEmpty).join('; ');
        
        // 保存cookie字符串到dio头
        Request.dio.options.headers['cookie'] = cookieString;
        if (isDebug) logger.d('[Cookie] 设置Dio cookie: $cookieString');
        
        // 由于webview_cookie_manager在Windows上不可用，我们直接使用cookie字符串
        // 这里我们需要手动创建Cookie对象，确保在所有平台上都能正常工作
        final List<Cookie> cookies = cookiesList.map((cookieMap) {
          final name = cookieMap['name'] as String? ?? '';
          final value = cookieMap['value'] as String? ?? '';
          return Cookie(name, value);
        }).toList();
        
        // 保存到cookie管理器
        await Request.cookieManager.cookieJar
            .saveFromResponse(Uri.parse(HttpString.baseUrl), cookies);
        if (isDebug) logger.d('[Cookie] 保存cookies到baseUrl成功');
        
        // 同时保存到其他域名
        await Request.cookieManager.cookieJar
            .saveFromResponse(Uri.parse(HttpString.apiBaseUrl), cookies);
        await Request.cookieManager.cookieJar
            .saveFromResponse(Uri.parse(HttpString.tUrl), cookies);
        if (isDebug) logger.d('[Cookie] 保存cookies到其他域名成功');
      } else {
        if (isDebug) logger.w('[Cookie] 未获取到Windows cookies');
      }
    } catch (e) {
      logger.e('[Cookie] 获取Windows cookies失败: $e');
    }
  }
}
