import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_toast.dart';
import 'error_view.dart';
import '../../core/network/api_exceptions.dart';

/// A standard AsyncValue builder widget that handles:
/// - Skeleton shimmer during loading
/// - Empty state with pull-to-refresh
/// - Error handling with [ErrorView] retry and [AppToast.error] notification
/// - Pull-to-refresh integration
class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.asyncValue,
    required this.skeleton,
    required this.builder,
    this.onRefresh,
    this.isEmpty,
    this.emptyState,
    this.onRetry,
    this.errorMessage,
  });

  final AsyncValue<T> asyncValue;
  final Widget skeleton;
  final Widget Function(BuildContext context, T data) builder;
  final Future<void> Function()? onRefresh;
  final bool Function(T data)? isEmpty;
  final Widget? emptyState;
  final VoidCallback? onRetry;
  final String Function(Object error)? errorMessage;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        if (isEmpty != null && isEmpty!(data) && emptyState != null) {
          Widget emptyWidget = emptyState!;
          if (onRefresh != null) {
            emptyWidget = RefreshIndicator(
              onRefresh: onRefresh!,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: emptyState,
                  ),
                ],
              ),
            );
          }
          return emptyWidget;
        }

        Widget content = builder(context, data);
        if (onRefresh != null) {
          content = RefreshIndicator(
            onRefresh: onRefresh!,
            child: content,
          );
        }
        return content;
      },
      loading: () => skeleton,
      error: (e, st) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.error(context, friendlyError(e));
        });

        final message = errorMessage != null ? errorMessage!(e) : friendlyError(e);

        Widget errorWidget = ErrorView(
          message: message,
          onRetry: onRetry,
        );

        if (onRefresh != null) {
          errorWidget = RefreshIndicator(
            onRefresh: onRefresh!,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: errorWidget,
                ),
              ],
            ),
          );
        }

        return errorWidget;
      },
    );
  }
}
