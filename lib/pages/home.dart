import 'dart:ui';

import 'package:aaid/bloc/ads_manager/ads_manager_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  initState() {
    super.initState();
    context.read<AdsManagerBloc>().checkForUpdate();
    context.read<AdsManagerBloc>().createInterstitialAd();
    context.read<AdsManagerBloc>().initPlatformState();
  }

  @override
  void dispose() {
    context.read<AdsManagerBloc>().disposeAds();
    super.dispose();
  }

  BoxShadow boxShadow = const BoxShadow(
      color: Color(0xff303030), blurRadius: 5, offset: Offset(0, 3));

  @override
  Widget build(BuildContext context) {
    context.read<AdsManagerBloc>().createAnchoredBanner(context);
    return BlocBuilder<AdsManagerBloc, AdsManagerState>(
        builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AAID'),
          actions: [
            //IconButton(
            //  onPressed: () {
            //    print('Push more');
            //  },
            //  icon: const Icon(Icons.more_vert),
            //)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () {
                    context.read<AdsManagerBloc>().requestReview();
                  },
                  child: const Text('Califica esta aplicación'),
                ),
                PopupMenuItem(
                  onTap: () {
                    context.read<AdsManagerBloc>().whatchInStore();
                  },
                  child: const Text('Ver en Google Play'),
                ),
              ],
            )
          ],
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [boxShadow],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Text(
                      'AAID (ID de publicidad de Google)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(
                    color: Color(0xff303030),
                    height: 2,
                  ),
                  Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(state.advertisingId!)),
                ],
              ),
            ),
            Text('Límite de seguimiento de anuncios ${state.available}'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: GestureDetector(
                onTap: () {
                  context.read<AdsManagerBloc>().share();
                },
                child: container('Compartir'),
              ),
            ),
            GestureDetector(
              onTap: () {
                context.read<AdsManagerBloc>().copy(context);
              },
              child: container('Copiar'),
            ),
          ],
        ),
        bottomNavigationBar: state.widget,
      );
    });
  }

  Widget container(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(25),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 50),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
