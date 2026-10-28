import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_preferences_provider.dart';
import '../screens/catalog/cart_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/invoices/invoice_detail_screen.dart';
import '../screens/invoices/invoices_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/setup_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/orders/new_shop_order_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/shop_order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/price_list/price_list_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/shops/shop_form_screen.dart';
import '../screens/shops/shop_detail_screen.dart';
import '../screens/shops/shops_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final savedToken = prefs.getString(AppConfig.accessTokenKey);
  final isLoggedIn = savedToken != null && savedToken.isNotEmpty;

  // Determine initial location directly without flashing login screen
  final initialLocation = isLoggedIn ? '/home' : '/login';

  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final onLogin = loc == '/login';
      final onSetup = loc == '/setup';

      // Check current token in preferences for immediate synchronous truth
      final currentToken = prefs.getString(AppConfig.accessTokenKey);
      final hasToken = currentToken != null && currentToken.isNotEmpty;

      // When logged out or token cleared, force redirect to login
      if (!hasToken && !auth.isAuthenticated) {
        if (onLogin || onSetup) return null;
        return '/login';
      }

      // If user is authenticated or has active token and tries to access login
      if ((hasToken || auth.isAuthenticated) && onLogin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const CupertinoPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/setup',
        redirect: (context, state) => kReleaseMode ? '/login' : null,
        pageBuilder: (context, state) =>
            const CupertinoPage(child: SetupScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const CupertinoPage(child: HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalog',
              pageBuilder: (context, state) =>
                  const CupertinoPage(child: CatalogScreen()),
              routes: [
                GoRoute(
                  path: 'product/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: ProductDetailScreen(
                        productId: state.pathParameters['id']!),
                  ),
                ),
                GoRoute(
                  path: 'cart',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: const CartScreen(),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              pageBuilder: (context, state) =>
                  const CupertinoPage(child: OrdersScreen()),
              routes: [
                GoRoute(
                  path: 'shop/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: ShopOrderDetailScreen(
                        orderId: state.pathParameters['id']!),
                  ),
                ),
                GoRoute(
                  path: 'new-shop-order',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: const NewShopOrderScreen(),
                  ),
                ),
                GoRoute(
                  path: 'direct-sale',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: const NewShopOrderScreen(),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/shops',
              pageBuilder: (context, state) =>
                  const CupertinoPage(child: ShopsScreen()),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: const ShopFormScreen(),
                  ),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child:
                        ShopDetailScreen(shopId: state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) => CupertinoPage(
                        key: state.pageKey,
                        child: ShopFormScreen(
                            shopId: state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              pageBuilder: (context, state) =>
                  const CupertinoPage(child: MoreScreen()),
              routes: [
                GoRoute(
                  path: 'invoices',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: const InvoicesScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: ':id',
                      parentNavigatorKey: rootNavigatorKey,
                      pageBuilder: (context, state) => CupertinoPage(
                        key: state.pageKey,
                        child: InvoiceDetailScreen(
                            invoiceId: state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'profile',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: const ProfileScreen(),
                  ),
                ),
                GoRoute(
                  path: 'price-list',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CupertinoPage(
                    key: state.pageKey,
                    child: const PriceListScreen(),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
