import 'package:flutter/material.dart';
import '../models/receipt_model.dart';

class ReceiptService extends ChangeNotifier {
  List<Receipt> _receipts = [];
  List<Receipt> _filteredReceipts = [];
  Set<String> _selectedReceiptIds = {};
  String _searchQuery = '';
  String _selectedFilter = 'All';

  List<Receipt> get receipts => _filteredReceipts;
  Set<String> get selectedReceiptIds => _selectedReceiptIds;
  bool get hasSelectedReceipts => _selectedReceiptIds.isNotEmpty;
  int get selectedCount => _selectedReceiptIds.length;
  String get selectedFilter => _selectedFilter;

  ReceiptService() {
    _loadSampleReceipts();
    _applyFilters();
  }

  void _loadSampleReceipts() {
    _receipts = [];
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredReceipts = _receipts.where((receipt) {
      // Apply search filter
      bool matchesSearch =
          _searchQuery.isEmpty ||
          receipt.transactionId.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          receipt.amount.toString().contains(_searchQuery) ||
          receipt.dateTime.toString().contains(_searchQuery);

      // Apply category filter
      bool matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'This Month' &&
              receipt.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              )) ||
          (_selectedFilter == 'Last Month' &&
              receipt.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 60)),
              ) &&
              receipt.dateTime.isBefore(
                DateTime.now().subtract(const Duration(days: 30)),
              )) ||
          receipt.paymentMethod == _selectedFilter ||
          receipt.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    notifyListeners();
  }

  void toggleReceiptSelection(String id) {
    if (_selectedReceiptIds.contains(id)) {
      _selectedReceiptIds.remove(id);
    } else {
      _selectedReceiptIds.add(id);
    }
    notifyListeners();
  }

  void selectAllReceipts() {
    _selectedReceiptIds = _filteredReceipts
        .map((receipt) => receipt.id)
        .toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedReceiptIds.clear();
    notifyListeners();
  }

  List<Receipt> getSelectedReceipts() {
    return _receipts
        .where((receipt) => _selectedReceiptIds.contains(receipt.id))
        .toList();
  }

  void downloadReceipt(String id) {
    // In a real app, this would download the receipt
  }

  void downloadSelectedReceipts() {
    // In a real app, this would download all selected receipts
  }

  void shareReceipt(String id) {
    // In a real app, this would share the receipt
  }

  void shareSelectedReceipts() {
    // In a real app, this would share all selected receipts
  }
}
