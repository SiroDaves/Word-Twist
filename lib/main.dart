import 'package:flutter/material.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_twist/data/word_repo.dart';
import 'package:word_twist/game/user_prefs_impl.dart';
import 'package:word_twist/ui/admob_config.dart';
import 'package:word_twist/ui/word_twist_app.dart';

void main() async {
  WordsDataSource dataSource = new WordsDataSource();
  if (!await dataSource.isDbLoaded()) {
    await dataSource.loadDatabase();
  }
  await SharedPreferences.getInstance();
  await UserPrefsImpl.instance().init();
  FirebaseAdMob.instance.initialize(appId: AdMobConfig.adMobAppId);
  runApp(WordTwistApp());
}