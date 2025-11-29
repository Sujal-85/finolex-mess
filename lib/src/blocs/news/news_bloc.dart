import 'package:flutter_bloc/flutter_bloc.dart';
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
      await Future.delayed(const Duration(seconds: 2)); // Simulate API

      final List<Map<String, dynamic>> mockNews = [
        {
          'id': '1',
          'title': 'Diwali Special Lunch',
          'content':
              'Join us for a grand feast this Diwali! Special sweets and thali will be served.',
          'date': '2025-11-01',
          'image': 'assets/images/diwali.png', // Placeholder
          'isImportant': true,
        },
        {
          'id': '2',
          'title': 'Mess Fee Payment Deadline',
          'content':
              'Please clear your mess dues for the month of October by 5th Nov to avoid late fees.',
          'date': '2025-10-28',
          'image': 'assets/images/payment.png', // Placeholder
          'isImportant': true,
        },
        {
          'id': '3',
          'title': 'New Breakfast Menu',
          'content':
              'We have introduced Poha and Upma in the breakfast menu based on student feedback.',
          'date': '2025-10-25',
          'image': 'assets/images/breakfast.png', // Placeholder
          'isImportant': false,
        },
        {
          'id': '4',
          'title': 'Maintenance Notice',
          'content':
              'The canteen will be closed for maintenance on Sunday evening from 4 PM to 6 PM.',
          'date': '2025-10-20',
          'image': 'assets/images/maintenance.png', // Placeholder
          'isImportant': false,
        },
      ];

      emit(state.copyWith(status: NewsStatus.success, newsItems: mockNews));
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
