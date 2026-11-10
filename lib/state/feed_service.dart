import 'package:flutter/material.dart';
import '../database/models.dart';

/// Posts shown in the feed and which prompt and answer are being viewed
class FeedService with ChangeNotifier {
  String _viewingPost = "____________";
  Color _viewingColor = Colors.amber;
  List<DbPost> _currentPosts = List<DbPost>.empty(growable: true);
  String? _currentFeedPromptId;
  String? get currentFeedPromptId => _currentFeedPromptId;
  String get viewingPost => _viewingPost;
  List<DbPost>? get currentPosts => _currentPosts;
  Color? get viewingColor => _viewingColor;

  void setCurrentFeedPromptId(String s){
    _currentFeedPromptId = s;
    notifyListeners();
  }
  void setViewingColor(Color c){
    _viewingColor = c;
    notifyListeners();
  }

  void setCurrentPosts(List<DbPost> posts){
    _currentPosts = posts;
    notifyListeners();
  }
  void setViewingPost(String viewingPost){
    _viewingPost = viewingPost;
    notifyListeners();
  }

  void clearviewingPost(){
    _viewingPost = "____________";
    notifyListeners();
  }

  void clearViewingColor(){
    _viewingColor = Colors.amber;
    notifyListeners();
  }

  /// Forgets the feed, so the next user starts fresh
  void logout(){
    _viewingPost = "____________";
    _viewingColor = Colors.amber;
    _currentPosts = List<DbPost>.empty(growable: true);
    _currentFeedPromptId = null;
    notifyListeners();
  }
}
