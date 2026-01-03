import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipala/utils/login.dart';
import 'package:pilipala/utils/cookie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_platform/universal_platform.dart';
import 'controller.dart';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:webview_windows/webview_windows.dart' as webview_windows if (dart.library.html) '';

class WebviewPage extends StatefulWidget {
  const WebviewPage({super.key});

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

// Windows平台的webview组件
class WindowsWebView extends StatefulWidget {
  final String url;
  final String type;
  final Function()? onLoginSuccess;
  final void Function(bool) onLoadShowChange;

  const WindowsWebView({
    Key? key,
    required this.url,
    required this.type,
    this.onLoginSuccess,
    required this.onLoadShowChange,
  }) : super(key: key);

  @override
  State<WindowsWebView> createState() => _WindowsWebViewState();
}

class _WindowsWebViewState extends State<WindowsWebView> {
  late final webview_windows.WebviewController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = webview_windows.WebviewController();
    await _controller.initialize();

    // 设置基本配置
    await _controller.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');

    // 将控制器设置到SetCookie类中，以便获取cookies
    SetCookie.setWindowsWebViewController(_controller);

    // 监听加载状态
    _controller.loadingState.listen((state) {
      switch (state) {
        case webview_windows.LoadingState.loading:
          widget.onLoadShowChange(true);
          break;
        default:
          // 所有非loading状态都隐藏加载指示器
          widget.onLoadShowChange(false);
          break;
      }
    });

    // 监听URL变化，用于登录检测
    _controller.url.listen((url) {
      if (widget.type == 'login') {
        if (url.startsWith(
                'https://passport.bilibili.com/web/sso/exchange_cookie') ||
            url.startsWith('https://m.bilibili.com/')) {
          widget.onLoginSuccess?.call();
        }
      }
    });

    // 加载URL
    await _controller.loadUrl(widget.url);

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return webview_windows.Webview(_controller);
  }
}

class _WebviewPageState extends State<WebviewPage> {
  final WebviewController _webviewController = Get.put(WebviewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            _webviewController.pageTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actions: [
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                if (!UniversalPlatform.isWindows) {
                  _webviewController.controller?.reload();
                }
              },
              icon: Icon(Icons.refresh_outlined,
                  color: Theme.of(context).colorScheme.primary),
            ),
            IconButton(
              onPressed: () {
                launchUrl(Uri.parse(_webviewController.url));
              },
              icon: Icon(Icons.open_in_browser_outlined,
                  color: Theme.of(context).colorScheme.primary),
            ),
            Obx(
              () => _webviewController.type.value == 'login'
                  ? TextButton(
                      onPressed: () =>
                          LoginUtils.confirmLogin(null, _webviewController),
                      child: const Text('刷新登录状态'),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 12)
          ],
        ),
        body: Column(
          children: [
            Obx(
              () => AnimatedContainer(
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 350),
                height: _webviewController.loadShow.value ? 4 : 0,
                child: LinearProgressIndicator(
                  key: ValueKey(_webviewController.loadProgress),
                  value: _webviewController.loadProgress / 100,
                ),
              ),
            ),
            if (_webviewController.type.value == 'login')
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.onInverseSurface,
                padding: const EdgeInsets.only(
                    left: 12, right: 12, top: 6, bottom: 6),
                child: const Text('登录成功未自动跳转?  请点击右上角「刷新登录状态」'),
              ),
            Expanded(
              child: UniversalPlatform.isWindows
                  ? WindowsWebView(
                      url: _webviewController.url,
                      type: _webviewController.type.value,
                      onLoginSuccess: () =>
                          LoginUtils.confirmLogin(null, _webviewController),
                      onLoadShowChange: (bool show) {
                        _webviewController.loadShow.value = show;
                      },
                    )
                  : WebViewWidget(controller: _webviewController.controller!),
            ),
          ],
        ));
  }
}
