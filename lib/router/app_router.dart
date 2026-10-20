import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/catalog/cart_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/invoices/invoice_detail_screen.dart';
import '../screens/invoices/invoices_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/orders/new_shop_order_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/shop_order_detail_screen.dart';
import '../screens/payments/new_payment_screen.dart';
import '../screens/payments/payments_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/shell/splash_screen.dart';
import '../screens/shops/shop_form_screen.dart';
import '../screens/shops/shop_detail_screen.dart';
import '../screens/shops/shops_screen.dart';
import '../screens/stock/stock_screen.dart';
import '../screens/ledger/ledger_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final onLogin = loc == '/login';
      final onSplash = loc == '/splash';

      if (auth.status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return onLogin ? null : '/login';
      }
      // Authenticated
      if (onLogin || onSplash) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            CupertinoPage(child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            CupertinoPage(child: const LoginScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalog',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const CatalogScreen()),
            ),
            GoRoute(
              path: '/catalog/product/:id',
              pageBuilder: (context, state) => CupertinoPage(
                child: ProductDetailScreen(
                    productId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/catalog/cart',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const CartScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const OrdersScreen()),
            ),
            GoRoute(
              path: '/orders/mfr/:id',
              pageBuilder: (context, state) => CupertinoPage(
                child: OrderDetailScreen(orderId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/orders/shop/:id',
              pageBuilder: (context, state) => CupertinoPage(
                child:
                    ShopOrderDetailScreen(orderId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/orders/new-shop-order',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const NewShopOrderScreen()),
            ),
            GoRoute(
              path: '/orders/direct-sale',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const NewShopOrderScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/shops',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const ShopsScreen()),
            ),
            GoRoute(
              path: '/shops/new',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const ShopFormScreen()),
            ),
            GoRoute(
              path: '/shops/:id',
              pageBuilder: (context, state) => CupertinoPage(
                child: ShopDetailScreen(shopId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/shops/:id/edit',
              pageBuilder: (context, state) => CupertinoPage(
                child:
                    ShopFormScreen(shopId: state.pathParameters['id']!),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const MoreScreen()),
            ),
            GoRoute(
              path: '/more/invoices',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const InvoicesScreen()),
            ),
            GoRoute(
              path: '/more/invoices/:id',
              pageBuilder: (context, state) => CupertinoPage(
                child:
                    InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/more/payments',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const PaymentsScreen()),
            ),
            GoRoute(
              path: '/more/payments/new',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const NewPaymentScreen()),
            ),
            GoRoute(
              path: '/more/ledger',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const LedgerScreen()),
            ),
            GoRoute(
              path: '/more/stock',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const StockScreen()),
            ),
            GoRoute(
              path: '/more/profile',
              pageBuilder: (context, state) =>
                  CupertinoPage(child: const ProfileScreen()),
            ),
          ]),
        ],
      ),
    ],
  );
});
