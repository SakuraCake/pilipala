import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/pages/mine/index.dart';
import 'package:pilipala/utils/feed_back.dart';
import './controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final HomeController _homeController = Get.put(HomeController());
  List videoList = [];
  late Stream<bool> stream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    stream = _homeController.searchBarStream.stream;
  }

  showUserBottomSheet() {
    feedBack();
    showModalBottomSheet(
      context: context,
      builder: (_) => const SizedBox(
        height: 450,
        child: MinePage(),
      ),
      clipBehavior: Clip.hardEdge,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: Platform.isAndroid
            ? SystemUiOverlayStyle(
                statusBarIconBrightness:
                    Theme.of(context).brightness == Brightness.dark
                        ? Brightness.light
                        : Brightness.dark,
              )
            : Theme.of(context).brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          CustomAppBar(
            stream: _homeController.hideSearchBar
                ? stream
                : StreamController<bool>.broadcast().stream,
            ctr: _homeController,
            callback: showUserBottomSheet,
          ),
          if (_homeController.tabs.length > 1) ...[
            if (_homeController.enableGradientBg) ...[
              const CustomTabs(),
            ] else ...[
              Container(
                width: double.infinity,
                height: 52,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _homeController.tabController,
                  tabs: [
                    for (var i in _homeController.tabs) Tab(text: i['label'])
                  ],
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  enableFeedback: true,
                  splashBorderRadius: BorderRadius.circular(16),
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3,
                  unselectedLabelStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  onTap: (value) {
                    feedBack();
                    if (_homeController.initialIndex.value == value) {
                      _homeController.tabsCtrList[value]().animateToTop();
                    }
                    _homeController.initialIndex.value = value;
                  },
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
          ],
          Expanded(
            child: TabBarView(
              controller: _homeController.tabController,
              children: _homeController.tabsPageList,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Stream<bool>? stream;
  final HomeController? ctr;
  final Function? callback;

  const CustomAppBar({
    super.key,
    this.height = kToolbarHeight,
    this.stream,
    this.ctr,
    this.callback,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream!.distinct(),
      initialData: true,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        final RxBool isUserLoggedIn = ctr!.userLogin;
        final double top = MediaQuery.of(context).padding.top;
        return AnimatedOpacity(
          opacity: snapshot.data ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            curve: Curves.easeInOutCubicEmphasized,
            duration: const Duration(milliseconds: 500),
            height: snapshot.data ? top + 52 : top,
            padding: EdgeInsets.fromLTRB(14, top + 6, 14, 0),
            child: UserInfoWidget(
              top: top,
              ctr: ctr,
              userLogin: isUserLoggedIn,
              userFace: ctr?.userFace.value,
              callback: () => callback!(),
            ),
          ),
        );
      },
    );
  }
}

class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({
    Key? key,
    required this.top,
    required this.userLogin,
    required this.userFace,
    required this.callback,
    required this.ctr,
  }) : super(key: key);

  final double top;
  final RxBool userLogin;
  final String? userFace;
  final VoidCallback? callback;
  final HomeController? ctr;

  Widget buildLoggedInWidget(context) {
    return Stack(
      children: [
        NetworkImgLayer(
          type: 'avatar',
          width: 34,
          height: 34,
          src: userFace,
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => callback?.call(),
              splashColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: const BorderRadius.all(
                Radius.circular(50),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomSearchBar(ctr: ctr),
        if (userLogin.value) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => Get.toNamed('/whisper'),
            icon: const Icon(Icons.notifications_none),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          )
        ],
        const SizedBox(width: 8),
        Obx(
          () => userLogin.value
              ? buildLoggedInWidget(context)
              : DefaultUser(callback: () => callback!()),
        ),
      ],
    );
  }
}

class DefaultUser extends StatelessWidget {
  const DefaultUser({super.key, this.callback});
  final Function? callback;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.onSecondaryContainer.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: EdgeInsets.zero,
        minimumSize: const Size(38, 38),
      ),
      onPressed: () => callback?.call(),
      icon: Icon(
        Icons.person_rounded,
        size: 22,
        color: colorScheme.primary,
      ),
    );
  }
}

class CustomTabs extends StatefulWidget {
  const CustomTabs({super.key});

  @override
  State<CustomTabs> createState() => _CustomTabsState();
}

class _CustomTabsState extends State<CustomTabs> {
  final HomeController _homeController = Get.put(HomeController());

  void onTap(int index) {
    feedBack();
    if (_homeController.initialIndex.value == index) {
      _homeController.tabsCtrList[index]().animateToTop();
    }
    _homeController.initialIndex.value = index;
    _homeController.tabController.index = index;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: Obx(
        () => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          scrollDirection: Axis.horizontal,
          itemCount: _homeController.tabs.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(width: 10);
          },
          itemBuilder: (BuildContext context, int index) {
            String label = _homeController.tabs[index]['label'];
            return Obx(
              () => CustomChip(
                onTap: () => onTap(index),
                label: label,
                selected: index == _homeController.initialIndex.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomChip extends StatelessWidget {
  final Function onTap;
  final String label;
  final bool selected;
  const CustomChip({
    super.key,
    required this.onTap,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorTheme = Theme.of(context).colorScheme;
    final TextStyle chipTextStyle = selected
        ? TextStyle(
            fontSize: 13,
            color: colorTheme.onPrimary,
            fontWeight: FontWeight.w500,
          )
        : TextStyle(
            fontSize: 13,
            color: colorTheme.onSecondaryContainer,
          );

    return FilterChip(
      label: Text(label, style: chipTextStyle),
      onSelected: (_) => onTap(),
      selected: selected,
      showCheckmark: false,
      backgroundColor: colorTheme.secondaryContainer,
      selectedColor: colorTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: selected ? 1 : 0,
      shadowColor: colorTheme.shadow,
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    Key? key,
    required this.ctr,
  }) : super(key: key);

  final HomeController? ctr;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: SearchBar(
        onTap: () => Get.toNamed('/search',
            parameters: {'hintText': ctr!.defaultSearch.value}),
        hintText: ctr!.defaultSearch.value,
        backgroundColor: MaterialStateProperty.all(
          colorScheme.onSecondaryContainer.withOpacity(0.05),
        ),
        leading: Icon(
          Icons.search_outlined,
          color: colorScheme.onSecondaryContainer,
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        padding: const MaterialStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 14),
        ),
        elevation: MaterialStateProperty.all(0),
        shadowColor: MaterialStateProperty.all(Colors.transparent),
      ),
    );
  }
}
