import 'package:flutter/material.dart';
import '../database/models.dart';

/// Today's prompts and the logged-in user's post for each one
class PromptService with ChangeNotifier {
  List<DbPost?> _userPostsForPrompts = List.empty(growable: true);
  List<DbPrompt> _prompts = List.empty(growable: true);
  List<DbPrompt>? get prompts => _prompts;
  List<DbPost?> get userPostsForPrompts => _userPostsForPrompts;

  void addPostForPrompt(DbPost? p){
    _userPostsForPrompts.add(p);
    notifyListeners();
  }

  void addPrompt(DbPrompt p){
    _prompts.add(p);
    notifyListeners();
  }

  void clearPrompts(){
    _prompts.clear();
  }

  void clearPostsForPrompts(){
    _userPostsForPrompts.clear();
    notifyListeners();
  }

  void logout() {
    clearPrompts();
    clearPostsForPrompts();
    notifyListeners();
  }
}
