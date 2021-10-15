import 'package:aaid/helpers/helpers.dart';
import 'package:advertising_id/advertising_id.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:in_app_review/in_app_review.dart';

part 'ads_manager_event.dart';
part 'ads_manager_state.dart';

const int maxFailedLoadAttempts = 5;

class AdsManagerBloc extends Bloc<AdsManagerEvent, AdsManagerState> {
  AdsManagerBloc() : super(AdsManagerState()) {
    on<AdsManagerEvent>(_onAdsManagerEvent);
  }
  _onAdsManagerEvent(
      AdsManagerEvent event, Emitter<AdsManagerState> emit) async {
    if (event is OnChangeBanner) {
      onChangeBanner(event, emit);
    } else if (event is OnChangeInterstitial) {
      onChangeInterstitial(event, emit);
    } else if (event is OnChangeAdvertisingId) {
      onChangeAdverstisingId(event, emit);
    }
  }

  var logger = Logger(
    printer: PrettyPrinter(
        methodCount: 2, // number of method calls to be displayed
        errorMethodCount: 8, // number of method calls if stacktrace is provided
        lineLength: 120, // width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: false // Should each log print contain a timestamp
        ),
  );

  void onChangeBanner(OnChangeBanner event, Emitter<AdsManagerState> emit) {
    emit(state.copyWith(
        isReadyBanner: event.isReadyBanner, widget: event.widget));
  }

  void onChangeInterstitial(
      OnChangeInterstitial event, Emitter<AdsManagerState> emit) {
    emit(state.copyWith(isReadyInterstital: event.isReadyInterstitial));
  }

  void onChangeAdverstisingId(
      OnChangeAdvertisingId event, Emitter<AdsManagerState> emit) {
    emit(state.copyWith(
        advertisingId: event.advertisingId,
        available: event.available,
        isLimitAdTrackingEnabled: event.isLimitAdTrackingEnabled));
  }

  void initPlatformState() async {
    String? advertisingId;
    bool? isLimitAdTrackingEnabled;
    try {
      advertisingId = await AdvertisingId.id(true);
    } on PlatformException {
      advertisingId = 'Failed to get platform version.';
    }

    try {
      isLimitAdTrackingEnabled = await AdvertisingId.isLimitAdTrackingEnabled;
    } on PlatformException {
      isLimitAdTrackingEnabled = false;
    }

    final available = isLimitAdTrackingEnabled! ? 'habilitado' : 'desabilitado';
    //if (!mounted) return;
    add(OnChangeAdvertisingId(
      advertisingId: advertisingId,
      isLimitAdTrackingEnabled: isLimitAdTrackingEnabled,
      available: available,
    ));
  }

  void share() async {
    Share.share(state.advertisingId!);
    showAd();
  }

  void copy(BuildContext context) async {
    showAd();
    Clipboard.setData(ClipboardData(text: state.advertisingId!));
    SnackBar? snackBar = const SnackBar(
        duration: Duration(milliseconds: 1200),
        content: Text('Se ha copiado al portapapeles'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  int _numInterstitialLoadAttempts = 0;
  InterstitialAd? _interstitialAd;
  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Ads.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          logger.i('$ad loaded');
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          add(OnChangeInterstitial(isReadyInterstitial: true));
        },
        onAdFailedToLoad: (LoadAdError error) {
          logger.e('InterstitialAd failed to load: $error.');
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          add(OnChangeInterstitial(isReadyInterstitial: false));
          if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            logger.e('InterstitialAd Failed to load: $error.');
            createInterstitialAd();
          } else {
            logger.w('Numero maximo de intentos alcanzado.');
          }
        },
      ),
    );
  }

  void showAd() async {
    if (state.isReadyInterstital!) {
      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          logger.i('ad onAdShowedFullScreenContent.');
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          logger.w('$ad onAdDismissedFullScreenContent.');
          ad.dispose();
          createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          logger.e('$ad onAdFailedToShowFullScreenContent: $error');
          ad.dispose();
          createInterstitialAd();
        },
      );
      await _interstitialAd?.show();
      _interstitialAd = null;
      add(OnChangeInterstitial(isReadyInterstitial: false));
      createInterstitialAd();
    }
  }

  //Banner Add configuration.

  initBanner(BuildContext context) {
    if (!_loadingAnchoredBanner) {
      createAnchoredBanner(context);
    }
  }

  BannerAd? _anchoredBanner;
  bool _loadingAnchoredBanner = false;

  Future<void> createAnchoredBanner(BuildContext context) async {
    _loadingAnchoredBanner = true;
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      logger.w('Unable to get height of anchored banner.');
      return;
    }
    final BannerAd banner = BannerAd(
      size: size,
      request: const AdRequest(),
      adUnitId: Ads.banerId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          logger.w('$BannerAd loaded.');
          _anchoredBanner = ad as BannerAd;
          add(OnChangeBanner(
              isReadyBanner: true,
              widget: SizedBox(
                width: _anchoredBanner?.size.width.toDouble(),
                height: _anchoredBanner?.size.height.toDouble(),
                child: AdWidget(ad: _anchoredBanner!),
              )));
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          logger.e('$BannerAd failedToLoad: $error');
          ad.dispose();
          add(OnChangeBanner(
              isReadyBanner: false,
              widget: const SizedBox(height: 0, width: 0)));
        },
        onAdOpened: (Ad ad) {
          logger.i('$BannerAd onAdOpened.');
        },
        onAdClosed: (Ad ad) {
          logger.i('$BannerAd onAdClosed.');
          add(OnChangeBanner(
              isReadyBanner: false,
              widget: const SizedBox(height: 0, width: 0)));
        },
      ),
    );
    return banner.load();
  }

  disposeAds() async {
    await _anchoredBanner?.dispose();
    await _interstitialAd?.dispose();
    logger.w('$BannerAd disposed.');
    logger.w('$InterstitialAd disposed.');
    add(OnChangeBanner(
        isReadyBanner: false, widget: const SizedBox(height: 0, width: 0)));
  }

  final InAppReview inAppReview = InAppReview.instance;

  void requestReview() async {
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
    logger.w('App no disponible en el playstore');
  }

  void whatchInStore() {
    StoreRedirect.redirect(androidAppId: "com.skizofrenks.aaid");
  }

  //In app Update code.
  AppUpdateInfo? _updateInfo;
  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      _updateInfo = info;

      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        logger.i('Actualización disponible');
        InAppUpdate.performImmediateUpdate()
            .catchError((e) => logger.e(e.toString()));
      } else if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateNotAvailable) {
        logger.v('Actualización no disponible');
      } else if (_updateInfo?.updateAvailability ==
          UpdateAvailability.unknown) {
        logger.v('Ni idea de qué pasa.');
      }
    }).catchError((e) {
      logger.e(e.toString());
    });
  }
}
