import 'dart:async';

import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/common/skeleton/dynamic_card.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'package:pilipala/common/widgets/no_data.dart';
import 'package:pilipala/models/dynamics/result.dart';
import 'package:pilipala/plugin/pl_popup/index.dart';
import 'package:pilipala/utils/feed_back.dart';
import 'package:pilipala/utils/main_stream.dart';
import 'package:pilipala/utils/route_push.dart';
import 'package:pilipala/utils/storage.dart';

import '../mine/controller.dart';
import 'controller.dart';
import 'widgets/dynamic_panel.dart';
import 'up_dynamic/route_panel.dart';
import 'widgets/up_panel.dart';

class DynamicsPage extends StatefulWidget {
  const DynamicsPage({super.key});

  @override
  State<DynamicsPage> createState() => _DynamicsPageState();
}

class _DynamicsPageState extends State<DynamicsPage>
    with AutomaticKeepAliveClientMixin {
  final DynamicsController _dynamicsController = Get.put(DynamicsController());
  final MineController mineController = Get.put(MineController());
  late Future _futureBuilderFuture;
  late Future _futureBuilderFutureUp;
  Box userInfoCache = GStrorage.userInfo;
  late ScrollController scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureBuilderFuture = _dynamicsController.queryFollowDynamic();
    _futureBuilderFutureUp = _dynamicsController.queryFollowUp();
    scrollController = _dynamicsController.scrollController;
    scrollController.addListener(
      () async {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          EasyThrottle.throttle(
              'queryFollowDynamic', const Duration(seconds: 1), () {
            _dynamicsController.queryFollowDynamic(type: 'onLoad');
          });
        }
        handleScrollEvent(scrollController);
      },
    );

    _dynamicsController.userLogin.listen((status) {
      if (mounted) {
        setState(() {
          _futureBuilderFuture = _dynamicsController.queryFollowDynamic();
          _futureBuilderFutureUp = _dynamicsController.queryFollowUp();
        });
      }
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: SizedBox(
          height: 34,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() {
                    if (_dynamicsController.mid.value != -1 &&
                        _dynamicsController.upInfo.value.uname != null) {
                      return SizedBox(
                        height: 36,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: Text(
                              '${_dynamicsController.upInfo.value.uname!}的动态',
                              key: ValueKey<String>(
                                  _dynamicsController.upInfo.value.uname!),
                              style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .fontSize,
                              )),
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
                  Obx(
                    () => _dynamicsController.userLogin.value
                        ? Visibility(
                            visible: _dynamicsController.mid.value == -1,
                            child: SegmentedButton<int>(
                              segments: [
                                ButtonSegment<int>(
                                  value: 0,
                                  label: Text('全部'),
                                ),
                                ButtonSegment<int>(
                                  value: 1,
                                  label: Text('投稿'),
                                ),
                                ButtonSegment<int>(
                                  value: 2,
                                  label: Text('番剧'),
                                ),
                                ButtonSegment<int>(
                                  value: 3,
                                  label: Text('专栏'),
                                ),
                              ],
                              selected: <int>{
                                _dynamicsController.initialValue.value
                              },
                              onSelectionChanged: (Set<int> newSelection) {
                                feedBack();
                                _dynamicsController
                                    .onSelectType(newSelection.first);
                              },
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                textStyle: MaterialStateProperty.all(
                                  Theme.of(context).textTheme.labelMedium,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          )
                        : Text('动态',
                            style: Theme.of(context).textTheme.titleMedium),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _dynamicsController.onRefresh(),
        child: CustomScrollView(
          controller: _dynamicsController.scrollController,
          slivers: [
            FutureBuilder(
              future: _futureBuilderFutureUp,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data == null) {
                    return const SliverToBoxAdapter(child: SizedBox());
                  }
                  Map data = snapshot.data;
                  if (data['status']) {
                    return Obx(
                      () => UpPanel(
                        upData: _dynamicsController.upData.value,
                        onClickUpCb: (data) {
                          // _dynamicsController.onTapUp(data);
                          Navigator.push(
                            context,
                            PlPopupRoute(
                              child: OverlayPanel(
                                  ctr: _dynamicsController, upInfo: data),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    );
                  }
                } else {
                  return const SliverToBoxAdapter(
                      child: SizedBox(
                    height: 90,
                    child: UpPanelSkeleton(),
                  ));
                }
              },
            ),
            FutureBuilder(
              future: _futureBuilderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data == null) {
                    return const SliverToBoxAdapter(child: SizedBox());
                  }
                  Map? data = snapshot.data;
                  if (data != null && data['status']) {
                    List<DynamicItemModel> list =
                        _dynamicsController.dynamicsList;
                    return Obx(
                      () {
                        if (list.isEmpty) {
                          if (_dynamicsController.isLoadingDynamic.value) {
                            return skeleton();
                          } else {
                            return const NoData();
                          }
                        } else {
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return DynamicPanel(item: list[index]);
                              },
                              childCount: list.length,
                            ),
                          );
                        }
                      },
                    );
                  } else {
                    return HttpError(
                      errMsg: data?['msg'] ?? '请求异常',
                      btnText: data?['code'] == -101 ? '去登录' : null,
                      fn: () {
                        if (data?['code'] == -101) {
                          RoutePush.loginRedirectPush();
                        } else {
                          setState(() {
                            _futureBuilderFuture =
                                _dynamicsController.queryFollowDynamic();
                            _futureBuilderFutureUp =
                                _dynamicsController.queryFollowUp();
                          });
                        }
                      },
                    );
                  }
                } else {
                  // 骨架屏
                  return skeleton();
                }
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40))
          ],
        ),
      ),
    );
  }

  Widget skeleton() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return const DynamicCardSkeleton();
      }, childCount: 5),
    );
  }
}
