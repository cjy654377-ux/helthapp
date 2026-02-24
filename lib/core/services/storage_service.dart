// Firebase Storage 서비스
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Firebase Storage 파일 업로드/삭제 서비스
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // --- 바디 프로그레스 사진 ---

  /// 바디 프로그레스 사진 업로드
  /// [uid]: 사용자 ID
  /// [file]: 이미지 파일
  /// [pose]: 포즈 (front, side, back)
  /// Returns: 다운로드 URL
  Future<String?> uploadBodyProgressPhoto({
    required String uid,
    required File file,
    required String pose,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'users/$uid/body_progress/${timestamp}_$pose.jpg';
      final ref = _storage.ref().child(path);

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'pose': pose,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );

      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // --- 프로필 사진 ---

  /// 프로필 사진 업로드 (기존 사진 덮어쓰기)
  Future<String?> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    try {
      final path = 'users/$uid/profile/avatar.jpg';
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // --- 팀 게시글 이미지 ---

  /// 팀 게시글 이미지 업로드
  Future<String?> uploadTeamPostImage({
    required String teamId,
    required String postId,
    required File file,
  }) async {
    try {
      final filename = '${const Uuid().v4()}.jpg';
      final path = 'teams/$teamId/posts/$postId/$filename';
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // --- 삭제 ---

  /// URL로 파일 삭제
  Future<bool> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 경로로 파일 삭제
  Future<bool> deleteByPath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 폴더 내 모든 파일 삭제 (예: 팀 게시글 삭제 시)
  Future<void> deleteFolder(String folderPath) async {
    try {
      final listResult = await _storage.ref().child(folderPath).listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
      // 하위 폴더도 재귀 삭제
      for (final prefix in listResult.prefixes) {
        await deleteFolder(prefix.fullPath);
      }
    } catch (_) {
      // 삭제 실패 무시
    }
  }
}

/// StorageService Riverpod Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
