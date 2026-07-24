enum ArcScrappyRepositoryStateStatus {
  restoring,
  unauthenticated,
  loading,
  loaded,
  empty,
  error,
}

class ArcScrappyRepositoryState<T> {
  const ArcScrappyRepositoryState({
    required this.status,
    this.data,
    this.error,
  });

  final ArcScrappyRepositoryStateStatus status;
  final T? data;
  final Object? error;

  bool get isLoading =>
      status == ArcScrappyRepositoryStateStatus.loading ||
      status == ArcScrappyRepositoryStateStatus.restoring;
  bool get isAuthenticated =>
      status == ArcScrappyRepositoryStateStatus.loaded ||
      status == ArcScrappyRepositoryStateStatus.empty ||
      status == ArcScrappyRepositoryStateStatus.loading;

  factory ArcScrappyRepositoryState.restoring() {
    return ArcScrappyRepositoryState<T>(
      status: ArcScrappyRepositoryStateStatus.restoring,
    );
  }

  factory ArcScrappyRepositoryState.unauthenticated() {
    return ArcScrappyRepositoryState<T>(
      status: ArcScrappyRepositoryStateStatus.unauthenticated,
    );
  }

  factory ArcScrappyRepositoryState.loading() {
    return ArcScrappyRepositoryState<T>(
      status: ArcScrappyRepositoryStateStatus.loading,
    );
  }

  factory ArcScrappyRepositoryState.loaded(T data) {
    return ArcScrappyRepositoryState<T>(
      status: ArcScrappyRepositoryStateStatus.loaded,
      data: data,
    );
  }

  factory ArcScrappyRepositoryState.empty() {
    return ArcScrappyRepositoryState<T>(
      status: ArcScrappyRepositoryStateStatus.empty,
    );
  }

  factory ArcScrappyRepositoryState.error(Object error) {
    return ArcScrappyRepositoryState<T>(
      status: ArcScrappyRepositoryStateStatus.error,
      error: error,
    );
  }
}
