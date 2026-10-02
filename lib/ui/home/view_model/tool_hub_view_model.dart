import 'package:flutter/material.dart';

import '../../../data/models/tool_model.dart';
import '../../../data/repositories/tool_repository.dart';

class ToolHubViewModel extends ChangeNotifier {
  ToolHubViewModel({ToolRepository? repository})
    : _repository = repository ?? const ToolRepository();

  final ToolRepository _repository;

  ToolCategory _selectedCategory = ToolCategory.all;
  int _selectedTab = 0;

  ToolCategory get selectedCategory => _selectedCategory;
  int get selectedTab => _selectedTab;

  List<ToolItem> get tools => _repository.toolsIn(_selectedCategory);

  String get listTitle => _selectedCategory == ToolCategory.all
      ? 'All tools'
      : '${_selectedCategory.label} tools';

  void selectCategory(ToolCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  ToolItem randomTool() => _repository.randomTool();
}
