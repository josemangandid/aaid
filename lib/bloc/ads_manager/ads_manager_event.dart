part of 'ads_manager_bloc.dart';

@immutable
abstract class AdsManagerEvent {}

class OnChangeBanner extends AdsManagerEvent {
  final bool? isReadyBanner;
  final Widget? widget;
  OnChangeBanner({
    this.isReadyBanner,
    this.widget,
  });
}

class OnChangeInterstitial extends AdsManagerEvent {
  final bool? isReadyInterstitial;
  OnChangeInterstitial({
    this.isReadyInterstitial,
  });
}

class OnChangeAdvertisingId extends AdsManagerEvent {
  final String? advertisingId;
  final String? available;
  final bool? isLimitAdTrackingEnabled;

  OnChangeAdvertisingId({
    this.advertisingId,
    this.available,
    this.isLimitAdTrackingEnabled,
  });
}
