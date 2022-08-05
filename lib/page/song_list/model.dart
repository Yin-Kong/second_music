import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:second_music/entity/enum.dart';
import 'package:second_music/entity/song_list.dart';
import 'package:second_music/page/home/my_song_list/model.dart';
import 'package:second_music/repository/local/database/song/dao.dart';
import 'package:second_music/repository/remote/platform/music_provider.dart';
import 'package:second_music/service/music_service.dart';

class SongListModel {
  final String plt;
  final String songListId;
  final SongListType songListType;

  var _songDao = SongDao();

  SongListModel(this.plt, this.songListId, this.songListType);

  SongList? _songList;
  var _songListStreamController = StreamController<SongList>.broadcast();

  Stream<SongList> get songListStream => _songListStreamController.stream;

  void refresh() async {
    SongList? songList =
        await _songDao.getSongList(plt, songListId, songListType);
    debugPrint(
        "refreshSongList: local, isCollected = $_isCollected, songTotal = ${songList?.songTotal}");

    _isCollected = songList != null;
    _isCollectedController.add(_isCollected);

    if (songList == null) {
      final musicPlatform = MusicPlatforms.fromString(plt)!;
      songList =
          await MusicProvider(musicPlatform).songList(songListType, songListId);
      debugPrint(
          "refreshSongList: remote, isCollected = $_isCollected, songTotal = ${songList.songTotal}");
    }

    if (songList != null) {
      _songList = songList;
      _songListStreamController.add(songList);
    }

    //更新AppBar颜色
    if (songList != null && songList.hasDisplayCover) {
      _generateBarColor(songList.displayCover);
    }
  }

  // 收藏状态
  bool _isCollected = false;

  bool get isCollected => _isCollected;
  var _isCollectedController = StreamController<bool>.broadcast();

  Stream<bool> get isCollectedStream => _isCollectedController.stream;

  /// 收藏歌单，保存歌单到数据库
  Future<void> togglePlaylistCollection(SongList songList) async {
    _isCollectedController.add(!_isCollected);
    var result = false;
    if (_isCollected) {
      result = await _songDao.deleteSongList(songList.id);
      _isCollected = false;
    } else {
      result = await _songDao.saveSongList(songList);
      _isCollected = true;
    }
    debugPrint(
        "togglePlaylistCollection, isCollected = $_isCollected, result = $result");
    if (result) {
      notifyMySongListChanged();
    }
    _isCollectedController.add(_isCollected);
  }

  // AppBar color
  var _barColor = Color(0xff8f8f8f);

  Color get barColor => _barColor;

  var _barColorController = StreamController<Color>.broadcast();

  Stream<Color> get barColorStream => _barColorController.stream;

  PaletteGenerator? _paletteGenerator;

  void _generateBarColor(String coverUrl) async {
    if (_paletteGenerator == null) {
      _paletteGenerator = await PaletteGenerator.fromImageProvider(
          CachedNetworkImageProvider(coverUrl),
          size: Size(140, 140));
    }
    _barColor = _headerBackgroundColor();
    _barColorController.add(_barColor);
  }

  Color _headerBackgroundColor() {
    var defColor = Color(0xff8f8f8f);
    if (_paletteGenerator == null) return defColor;
    return _paletteGenerator?.dominantColor?.color ??
        _paletteGenerator?.lightVibrantColor?.color ??
        _paletteGenerator?.lightMutedColor?.color ??
        _paletteGenerator?.darkVibrantColor?.color ??
        _paletteGenerator?.darkMutedColor?.color ??
        defColor;
  }

  ///播放全部歌曲
  void playAll() {
    if (_songList != null && _songList!.songs.isNotNullOrEmpty()) {
      MusicService.instance.playSongList(_songList!.songs);
    }
  }

  /// 编辑歌单，本地歌单：收藏到歌单、下一首播放、删除，平台歌单：没有删除功能
  void dispose() {
    _songListStreamController.close();
    _isCollectedController.close();
  }
}
