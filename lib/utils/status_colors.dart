import 'package:flutter/material.dart';

import '../models/finance.dart';
import '../models/orders.dart';
import '../theme/app_colors.dart';

Color manufacturerStatusColor(ManufacturerOrderStatus status) {
  switch (status) {
    case ManufacturerOrderStatus.submitted:
      return AppColors.info;
    case ManufacturerOrderStatus.confirmed:
      return AppColors.warning;
    case ManufacturerOrderStatus.partiallyDelivered:
      return AppColors.warning;
    case ManufacturerOrderStatus.delivered:
      return AppColors.success;
    case ManufacturerOrderStatus.cancelled:
      return AppColors.danger;
  }
}

Color shopStatusColor(ShopOrderStatus status) {
  switch (status) {
    case ShopOrderStatus.collected:
      return AppColors.info;
    case ShopOrderStatus.processing:
      return AppColors.warning;
    case ShopOrderStatus.loaded:
      return AppColors.brand;
    case ShopOrderStatus.delivered:
      return AppColors.success;
    case ShopOrderStatus.cancelled:
      return AppColors.danger;
  }
}

Color invoiceStatusColor(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.unpaid:
      return AppColors.danger;
    case InvoiceStatus.partiallyPaid:
      return AppColors.warning;
    case InvoiceStatus.paid:
      return AppColors.success;
  }
}
