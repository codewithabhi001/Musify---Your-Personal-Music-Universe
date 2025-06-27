import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  final PageController pageController = PageController();
  final RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    pageController.addListener(() {
      final newIndex = pageController.page?.round() ?? 0;
      if (newIndex != currentIndex.value) {
        currentIndex.value = newIndex;
      }
    });
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void changePage(int index) {
    pageController.jumpToPage(index);
    currentIndex.value = index;
  }
}
