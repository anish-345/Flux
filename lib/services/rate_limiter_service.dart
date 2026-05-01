/// Service for rate limiting
class RateLimiterService {
  // Rate limit configuration
  static const int defaultRequestsPerSecond = 10;
  static const int defaultBurstSize = 20;
  static const Duration defaultWindowDuration = Duration(seconds: 1);

  final Map<String, _RateLimitBucket> _buckets = {};
  final int requestsPerSecond;
  final int burstSize;
  final Duration windowDuration;

  RateLimiterService({
    this.requestsPerSecond = defaultRequestsPerSecond,
    this.burstSize = defaultBurstSize,
    this.windowDuration = defaultWindowDuration,
  });

  /// Check if request is allowed
  bool isAllowed(String identifier) {
    final bucket = _getBucket(identifier);
    return bucket.tryConsume();
  }

  /// Get remaining requests
  int getRemainingRequests(String identifier) {
    final bucket = _getBucket(identifier);
    return bucket.remaining;
  }

  /// Get time until next request is allowed
  Duration getTimeUntilAllowed(String identifier) {
    final bucket = _getBucket(identifier);
    return bucket.timeUntilAllowed;
  }

  /// Reset rate limit for identifier
  void reset(String identifier) {
    _buckets.remove(identifier);
  }

  /// Reset all rate limits
  void resetAll() {
    _buckets.clear();
  }

  /// Get bucket for identifier
  _RateLimitBucket _getBucket(String identifier) {
    return _buckets.putIfAbsent(
      identifier,
      () => _RateLimitBucket(
        capacity: burstSize,
        refillRate: requestsPerSecond,
        windowDuration: windowDuration,
      ),
    );
  }
}

/// Rate limit bucket (token bucket algorithm)
class _RateLimitBucket {
  final int capacity;
  final int refillRate;
  final Duration windowDuration;

  late double _tokens;
  late DateTime _lastRefillTime;

  _RateLimitBucket({
    required this.capacity,
    required this.refillRate,
    required this.windowDuration,
  }) {
    _tokens = capacity.toDouble();
    _lastRefillTime = DateTime.now();
  }

  /// Try to consume a token
  bool tryConsume() {
    _refill();

    if (_tokens >= 1) {
      _tokens -= 1;
      return true;
    }

    return false;
  }

  /// Refill tokens based on elapsed time
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefillTime);

    // Calculate tokens to add
    final tokensToAdd =
        (elapsed.inMilliseconds / windowDuration.inMilliseconds) * refillRate;

    _tokens = _min(_tokens + tokensToAdd, capacity.toDouble());
    _lastRefillTime = now;
  }

  /// Get remaining tokens
  int get remaining {
    _refill();
    return _tokens.toInt();
  }

  /// Get time until next token is available
  Duration get timeUntilAllowed {
    _refill();

    if (_tokens >= 1) {
      return Duration.zero;
    }

    // Time to generate 1 token
    final timePerToken = windowDuration.inMilliseconds / refillRate;
    return Duration(milliseconds: timePerToken.toInt());
  }
}

double _min(double a, double b) => a < b ? a : b;
