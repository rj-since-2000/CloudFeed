import 'package:flutter/material.dart';

class MessagesDelete with ChangeNotifier {
  int _count = 0;

  int get msgCount {
    return _count;
  }

  void setCount() {
    _count = _count + 1;
    notifyListeners();
  }

  void decreaseCount() {
    _count = _count - 1;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}
