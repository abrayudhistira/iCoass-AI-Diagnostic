import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/presentation/pages/widget/custom_button_navigation.dart';

/// Entry page for admin users that shows the bottom navigation bar
/// with the admin tab pre‑selected.
class AdminEntryPage extends StatelessWidget {
  const AdminEntryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The admin tab index is the last item (index 4) in the navigation list.
    return const MainNavigationWrapper(initialIndex: 0);
  }
}
