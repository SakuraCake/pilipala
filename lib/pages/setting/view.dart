import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipala/pages/setting/index.dart';
import 'package:pilipala/pages/setting/privacy_setting.dart';
import 'package:pilipala/pages/setting/recommend_setting.dart';
import 'package:pilipala/pages/setting/play_setting.dart';
import 'package:pilipala/pages/setting/style_setting.dart';
import 'package:pilipala/pages/setting/extra_setting.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // 当前选中的设置项索引
  late final RxInt selectedIndex;

  // 定义设置项数据
  late final List<Map<String, dynamic>> settingItems;

  @override
  void initState() {
    super.initState();
    // 初始化选中索引
    selectedIndex = 0.obs;
    // 初始化设置项数据
    settingItems = [
      {
        'title': '隐私设置',
        'icon': Icons.privacy_tip_outlined,
        'route': '/privacySetting',
        'content': const PrivacySetting(isEmbedded: true),
      },
      {
        'title': '推荐设置',
        'icon': Icons.recommend_outlined,
        'route': '/recommendSetting',
        'content': const RecommendSetting(isEmbedded: true),
      },
      {
        'title': '播放设置',
        'icon': Icons.play_arrow_outlined,
        'route': '/playSetting',
        'content': const PlaySetting(isEmbedded: true),
      },
      {
        'title': '外观设置',
        'icon': Icons.style_outlined,
        'route': '/styleSetting',
        'content': const StyleSetting(isEmbedded: true),
      },
      {
        'title': '其他设置',
        'icon': Icons.more_horiz_outlined,
        'route': '/extraSetting',
        'content': const ExtraSetting(isEmbedded: true),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.put(SettingController());
    // 获取屏幕宽度
    final double screenWidth = MediaQuery.of(context).size.width;
    // 定义宽屏阈值
    const double wideScreenThreshold = 768;
    // 判断是否为宽屏
    final bool isWideScreen = screenWidth > wideScreenThreshold;

    // 宽屏和窄屏使用完全独立的实现方案
    if (isWideScreen) {
      // 宽屏方案：左右分栏布局
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            '设置',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: Row(
          children: [
            // 左侧导航菜单
            Obx(() => NavigationDrawer(
                  selectedIndex: selectedIndex.value,
                  onDestinationSelected: (int index) {
                    // 只有点击设置项时才更新选中索引
                    if (index < settingItems.length) {
                      selectedIndex.value = index;
                    }
                    // 处理退出登录
                    else if (settingController.userLogin.value &&
                        index == settingItems.length) {
                      settingController.loginOut();
                    }
                    // 处理关于
                    else if (settingController.userLogin.value &&
                        index == settingItems.length + 1) {
                      Get.toNamed('/about');
                    }
                    // 处理未登录状态下的关于
                    else if (index == settingItems.length) {
                      Get.toNamed('/about');
                    }
                  },
                  children: [
                    ...settingItems.map((item) {
                      return NavigationDrawerDestination(
                        icon: Icon(item['icon']),
                        label: Text(item['title']),
                      );
                    }).toList(),
                    // 退出登录按钮 - 仅在登录状态下显示
                    if (settingController.userLogin.value)
                      NavigationDrawerDestination(
                        icon: const Icon(Icons.logout_outlined),
                        label: const Text('退出登录'),
                      ),
                    // 关于按钮
                    NavigationDrawerDestination(
                      icon: const Icon(Icons.info_outlined),
                      label: const Text('关于'),
                    ),
                  ],
                )),
            // 右侧内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        Obx(() => settingItems[selectedIndex.value]['content']),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 窄屏方案：列表布局
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            '设置',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: ListView(
          children: [
            ...settingItems.map((item) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  onTap: () => Get.toNamed(item['route']),
                  leading: Icon(item['icon']),
                  title: Text(item['title']),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Obx(
              () => Visibility(
                visible: settingController.userLogin.value,
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    onTap: () => settingController.loginOut(),
                    leading: const Icon(Icons.logout_outlined),
                    title: const Text('退出登录'),
                  ),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: ListTile(
                onTap: () => Get.toNamed('/about'),
                leading: const Icon(Icons.info_outlined),
                title: const Text('关于'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
  }
}
