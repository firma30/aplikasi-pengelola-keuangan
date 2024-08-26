import 'package:in_app_review/in_app_review.dart';

void rateApp() async {
  final InAppReview inAppReview = InAppReview.instance;

  if (await inAppReview.isAvailable()) {
    inAppReview.requestReview();
  } else {
    // Open the store listing if in-app review is not available
    inAppReview.openStoreListing(appStoreId: 'com.example.app');
  }
}
