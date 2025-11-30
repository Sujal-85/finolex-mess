import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  NewsBloc() : super(const NewsState()) {
    on<NewsLoadRequested>(_onLoadRequested);
    on<NewsRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    NewsLoadRequested event,
    Emitter<NewsState> emit,
  ) async {
    emit(state.copyWith(status: NewsStatus.loading));
    try {
      final api = ApiService();
      final response = await api.get('/announcements');
      final List<dynamic> data = response.data;
      final List<Map<String, dynamic>> newsItems = data.map((item) {
        return {
          'id': item['_id'] ?? 'unknown',
          'title': item['title'] ?? 'No Title',
          'content': item['description'] ?? 'No Description',
          'date': item['date'] ?? DateTime.now().toIso8601String(),
          'image': item['image'],
          'isImportant': item['type'] == 'urgent',
        };
      }).toList();

      emit(state.copyWith(status: NewsStatus.success, newsItems: newsItems));
    } catch (e) {
      emit(
        state.copyWith(
          status: NewsStatus.failure,
          errorMessage: 'Failed to load news',
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    NewsRefreshRequested event,
    Emitter<NewsState> emit,
  ) async {
    add(NewsLoadRequested());
  }
}
