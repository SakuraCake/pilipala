import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/http/member.dart';
import 'package:pilipala/utils/storage.dart';

class PrivacySetting extends StatefulWidget {
  const PrivacySetting({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<PrivacySetting> createState() => _PrivacySettingState();
}

class _PrivacySettingState extends State<PrivacySetting> {
  bool userLogin = false;
  Box userInfoCache = GStrorage.userInfo;
  var userInfo;

  @override
  void initState() {
    super.initState();
    userInfo = userInfoCache.get('userInfoCache');
    userLogin = userInfo != null;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!;
    TextStyle subTitleStyle = Theme.of(context)
        .textTheme
        .labelMedium!
        .copyWith(color: Theme.of(context).colorScheme.outline);

    // 构建页面内容
    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ListTile(
            onTap: () {
              if (!userLogin) {
                SmartDialog.showToast('登录后查看');
                return;
              }
              Get.toNamed('/blackListPage');
            },
            dense: false,
            title: Text('黑名单管理', style: titleStyle),
            subtitle: Text('已拉黑用户', style: subTitleStyle),
          ),
          ListTile(
            onTap: () {
              if (!userLogin) {
                SmartDialog.showToast('请先登录');
              }
              MemberHttp.cookieToKey();
            },
            dense: false,
            title: Text('刷新access_key', style: titleStyle),
          ),
        ],
      ),
    );

    // 如果是嵌入模式，直接返回内容；否则返回完整页面
    if (widget.isEmbedded) {
      return content;
    } else {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            '隐私设置',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: content,
      );
    }
  }
}
