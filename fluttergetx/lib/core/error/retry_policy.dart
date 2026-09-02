import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fluttergetx/core/error/failures.dart';

/// Configuration for retry behavior
class RetryPolicy {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool jitter;

  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitter = true,
  });

  /// Calculate delay for a given attempt number (0-indexed)
  Duration delayForAttempt(int attempt) {
    final exponentialDelay = baseDelay.inMilliseconds * pow(backoffMultiplier, attempt);
    final cappedDelay = min(exponentialDelay.toInt(), maxDelay.inMilliseconds);
    Duration delay = Duration(milliseconds: cappedDelay);

    if (jitter) {
      // Add ±25% jitter to prevent thundering herd
      final jitterAmount = (delay.inMilliseconds * 0.25).toInt();
      final random = Random();
      delay = Duration(
        milliseconds: delay.inMilliseconds + random.nextInt(jitterAmount * 2) - jitterAmount,
      );
    }

    return delay;
  }

  /// Default policy for rate limiting (429)
  static final RetryPolicy rateLimit = RetryPolicy(
    maxRetries: 3,
    baseDelay: Duration(seconds: 2),
    maxDelay: const Duration(seconds: 60),
    backoffMultiplier: 2.0,
    jitter: true,
  );

  /// Default policy for network errors
  static final RetryPolicy network = RetryPolicy(
    maxRetries: 2,
    baseDelay: Duration(seconds: 1),
    maxDelay: const Duration(seconds: 10),
    backoffMultiplier: 2.0,
    jitter: true,
  );

  /// No retry policy
  static final RetryPolicy none = RetryPolicy(maxRetries: 0);
}

/// Execute a function with retry logic based on the policy
/// Only retries on RateLimitFailure and NetworkFailure by default
Future<T> withRetry<T>({
  required Future<T> Function() action,
  required RetryPolicy policy,
  Set<Type> retryableFailures = const {
    RateLimitFailure,
    NetworkFailure,
    TimeoutFailure,
  },
  void Function(int attempt, Failure failure)? onRetry,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } catch (e) {
      final failure = e is Failure ? e : UnknownFailure(message: e.toString());

      // Check if we should retry
      final shouldRetry =
          attempt < policy.maxRetries &&
          retryableFailures.any((type) => failure.runtimeType == type);

      if (!shouldRetry) {
        rethrow;
      }

      // Special handling for RateLimitFailure - use server-provided retry-after if available
      Duration delay;
      if (failure is RateLimitFailure && failure.retryAfterSeconds != null) {
        delay = Duration(seconds: failure.retryAfterSeconds!);
      } else {
        delay = policy.delayForAttempt(attempt);
      }

      onRetry?.call(attempt, failure);

      debugPrint(
        '🔄 [RETRY] Attempt ${attempt + 1}/${policy.maxRetries} '
        'after ${delay.inMilliseconds}ms due to: ${failure.code} - ${failure.message}',
      );

      await Future.delayed(delay);
      attempt++;
    }
  }
}

/// Extension to add retry capability to any Future
extension RetryExtension<T> on Future<T> {
  Future<T> retry({
    RetryPolicy policy = const RetryPolicy(),
    Set<Type> retryableFailures = const {
      RateLimitFailure,
      NetworkFailure,
      TimeoutFailure,
    },
    void Function(int attempt, Failure failure)? onRetry,
  }) {
    return withRetry(
      action: () => this,
      policy: policy,
      retryableFailures: retryableFailures,
      onRetry: onRetry,
    );
  }
}