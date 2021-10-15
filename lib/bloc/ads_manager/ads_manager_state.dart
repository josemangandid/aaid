part of 'ads_manager_bloc.dart';

@immutable
class AdsManagerState {
  bool? isReadyBanner;
  Widget? widget;
  bool? isReadyInterstital;
  String? advertisingId;
  String? available;
  bool? isLimitAdTrackingEnabled;

  AdsManagerState({
    this.isReadyBanner = false,
    this.widget = const SizedBox(),
    this.isReadyInterstital = false,
    this.advertisingId = '',
    this.available = '',
    this.isLimitAdTrackingEnabled = false,
  });

  AdsManagerState copyWith({
    bool? isReadyBanner,
    Widget? widget,
    bool? isReadyInterstital,
    String? advertisingId,
    String? available,
    bool? isLimitAdTrackingEnabled,
  }) {
    return AdsManagerState(
      isReadyBanner: isReadyBanner ?? this.isReadyBanner,
      widget: widget ?? this.widget,
      isReadyInterstital: isReadyInterstital ?? this.isReadyInterstital,
      advertisingId: advertisingId ?? this.advertisingId,
      available: available ?? this.available,
      isLimitAdTrackingEnabled:
          isLimitAdTrackingEnabled ?? this.isLimitAdTrackingEnabled,
    );
  }
}
