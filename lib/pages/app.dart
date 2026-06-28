import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../desings/themes.dart';
import '../router/app_router.dart';

class TrakioApp extends ConsumerWidget {
  const TrakioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      theme: AppThemes.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
