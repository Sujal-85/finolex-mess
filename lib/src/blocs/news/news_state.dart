import 'package:equatable/equatable.dart';

enum NewsStatus { initial, loading, success, failure }

class NewsState extends Equatable {
  final NewsStatus status;
  final List<Map<String, dynamic>> newsItems;
  final String? errorMessage;

  const NewsState({
    this.status = NewsStatus.initial,
    this.newsItems = const [],
    this.errorMessage,
  });

  NewsState copyWith({
    NewsStatus? status,
    List<Map<String, dynamic>>? newsItems,
    String? errorMessage,
  }) {
    return NewsState(
      status: status ?? this.status,
      newsItems: newsItems ?? this.newsItems,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, newsItems, errorMessage];
}
