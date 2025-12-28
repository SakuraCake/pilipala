import 'package:flutter/cupertino.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/common/constants.dart';
import 'package:pilipala/http/video.dart';
import 'package:pilipala/models/home/rcmd/result.dart';
import 'package:pilipala/models/model_rec_video_item.dart';
import 'package:pilipala/utils/storage.dart';

class RcmdController extends GetxController with WidgetsBindingObserver {
  final ScrollController scrollController = ScrollController();
  int _currentPage = 0;
  // RxList<RecVideoItemAppModel> appVideoList = <RecVideoItemAppModel>[].obs;
  // RxList<RecVideoItemModel> webVideoList = <RecVideoItemModel>[].obs;
  bool isLoadingMore = true;
  OverlayEntry? popupDialog;
  Box setting = GStrorage.setting;
  RxInt crossAxisCount = 2.obs;
  late bool enableSaveLastData;
  late String defaultRcmdType = 'web';
  late RxList<dynamic> videoList;

  @override
  void onInit() {
    super.onInit();
    // 监听窗口大小变化
    WidgetsBinding.instance.addObserver(this);

    // 初始计算列数
    calculateCrossAxisCount();

    enableSaveLastData =
        setting.get(SettingBoxKey.enableSaveLastData, defaultValue: false);
    defaultRcmdType =
        setting.get(SettingBoxKey.defaultRcmdType, defaultValue: 'web');
    if (defaultRcmdType == 'web') {
      videoList = <RecVideoItemModel>[].obs;
    } else {
      videoList = <RecVideoItemAppModel>[].obs;
    }
  }

  @override
  void onClose() {
    // 移除窗口大小监听
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    // 窗口大小变化时重新计算列数
    calculateCrossAxisCount();
  }

  // 根据窗口宽度动态计算列数
  void calculateCrossAxisCount() {
    double screenWidth = Get.size.width;
    // 减去两侧安全间距
    double availableWidth = screenWidth - (StyleString.safeSpace * 2);

    // 基础列宽
    double baseColumnWidth = 200;

    // 根据可用宽度计算列数，至少2列，最多6列
    int calculatedColumns = (availableWidth / baseColumnWidth).floor();
    calculatedColumns = calculatedColumns.clamp(2, 6);

    crossAxisCount.value = calculatedColumns;
  }

  // 获取推荐
  Future queryRcmdFeed(type) async {
    if (isLoadingMore == false) {
      return;
    }
    if (type == 'onRefresh') {
      _currentPage = 0;
    }
    late final Map<String, dynamic> res;
    switch (defaultRcmdType) {
      case 'app':
      case 'notLogin':
        res = await VideoHttp.rcmdVideoListApp(
          loginStatus: defaultRcmdType != 'notLogin',
          freshIdx: _currentPage,
        );
        break;
      default: //'web'
        res = await VideoHttp.rcmdVideoList(
          freshIdx: _currentPage,
          ps: 20,
        );
    }
    if (res['status']) {
      if (type == 'init') {
        if (videoList.isNotEmpty) {
          videoList.addAll(res['data']);
        } else {
          videoList.value = res['data'];
        }
      } else if (type == 'onRefresh') {
        if (enableSaveLastData) {
          videoList.insertAll(0, res['data']);
        } else {
          videoList.value = res['data'];
        }
      } else if (type == 'onLoad') {
        videoList.addAll(res['data']);
      }
      _currentPage += 1;
      // 若videoList数量太小，可能会影响翻页，此时再次请求
      // 为避免请求到的数据太少时还在反复请求，要求本次返回数据大于1条才触发
      if (res['data'].length > 1 && videoList.length < 10) {
        queryRcmdFeed('onLoad');
      }
    }
    isLoadingMore = false;
    return res;
  }

  // 下拉刷新
  Future onRefresh() async {
    isLoadingMore = true;
    queryRcmdFeed('onRefresh');
  }

  // 上拉加载
  Future onLoad() async {
    queryRcmdFeed('onLoad');
  }

  // 返回顶部
  void animateToTop() async {
    // 检查滚动控制器是否已附加到滚动视图上
    if (scrollController.hasClients) {
      if (scrollController.offset >=
          MediaQuery.of(Get.context!).size.height * 5) {
        scrollController.jumpTo(0);
      } else {
        await scrollController.animateTo(0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    }
  }

  void blockUserCb(mid) {
    videoList.removeWhere((e) => e.owner.mid == mid);
    videoList.refresh();
    SmartDialog.showToast('已移除相关视频');
  }
}
