import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/models/user/fav_folder.dart';
import 'package:pilipala/pages/media/index.dart';
import 'package:pilipala/utils/utils.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage>
    with AutomaticKeepAliveClientMixin {
  late MediaController mediaController;
  late Future _futureBuilderFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    mediaController = Get.put(MediaController());
    _futureBuilderFuture = mediaController.queryFavFolder();
    mediaController.userLogin.listen((status) {
      setState(() {
        _futureBuilderFuture = mediaController.queryFavFolder();
      });
    });
  }

  @override
  void dispose() {
    mediaController.scrollController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('媒体库',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        controller: mediaController.scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // 媒体库快捷入口
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (int index = 0;
                        index < mediaController.list.length;
                        index++) ...[
                      ListTile(
                        onTap: () => mediaController.list[index]['onTap'](),
                        dense: false,
                        leading: Icon(
                          mediaController.list[index]['icon'],
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        minLeadingWidth: 0,
                        title: Text(
                          mediaController.list[index]['title'],
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                  ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      if (index < mediaController.list.length - 1) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 48,
                          endIndent: 16,
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 收藏夹部分
              Obx(() => mediaController.userLogin.value
                  ? favFolder(mediaController, context)
                  : const SizedBox()),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom +
                    kBottomNavigationBarHeight,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget favFolder(mediaController, context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '收藏夹',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (mediaController.favFolderData.value.count != null)
                      TextSpan(
                        text: ' (${mediaController.favFolderData.value.count})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _futureBuilderFuture = mediaController.queryFavFolder();
                });
              },
              icon: Icon(
                Icons.refresh_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 200,
          child: FutureBuilder(
              future: _futureBuilderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data == null) {
                    return const SizedBox();
                  }
                  Map data = snapshot.data as Map;
                  if (data['status']) {
                    List favFolderList =
                        mediaController.favFolderData.value.list!;
                    int favFolderCount =
                        mediaController.favFolderData.value.count!;
                    bool flag = favFolderCount > favFolderList.length;
                    return Obx(() => ListView.builder(
                          itemCount:
                              mediaController.favFolderData.value.list!.length +
                                  (flag ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (flag && index == favFolderList.length) {
                              return Padding(
                                  padding: const EdgeInsets.only(
                                      right: 8, bottom: 8),
                                  child: Material(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => Get.toNamed('/fav'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 180,
                                        height: 150,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 24,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '查看全部',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ));
                            } else {
                              return FavFolderItem(
                                  item: mediaController
                                      .favFolderData.value.list![index],
                                  index: index);
                            }
                          },
                          scrollDirection: Axis.horizontal,
                        ));
                  } else {
                    return SizedBox(
                      height: 160,
                      child: Center(
                        child: Text(
                          data['msg'],
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    );
                  }
                } else {
                  // 骨架屏
                  return const SizedBox();
                }
              }),
        ),
      ],
    );
  }
}

class FavFolderItem extends StatelessWidget {
  const FavFolderItem({super.key, this.item, this.index});
  final FavFolderItemData? item;
  final int? index;
  @override
  Widget build(BuildContext context) {
    String heroTag = Utils.makeHeroTag(item!.fid);
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(left: index == 0 ? 0 : 8, right: 8, bottom: 8),
      child: Material(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surface,
        child: InkWell(
          onTap: () => Get.toNamed('/favDetail', arguments: item, parameters: {
            'mediaId': item!.id.toString(),
            'heroTag': heroTag,
            'isOwner': '1',
          }),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 110,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: colorScheme.surfaceVariant,
                  ),
                  child: LayoutBuilder(
                    builder: (context, BoxConstraints box) {
                      return Hero(
                        tag: heroTag,
                        child: NetworkImgLayer(
                          src: item!.cover,
                          width: box.maxWidth,
                          height: box.maxHeight,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item!.title ?? '未命名收藏夹',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '共${item!.mediaCount}条视频',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall!
                            .copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
