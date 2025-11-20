import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 문의 유형 목록
enum InquiryType {
  account('계정/로그인 문의'),
  participation('참가/사진 승인 문의'),
  ranking('투표/랭킹 오류 문의'),
  payment('결제/광고 문의'),
  bug('버그 신고 및 개선 제안'),
  other('기타 문의');

  final String displayName;
  const InquiryType(this.displayName);
}


@immutable
class InquiryData {
  final String userId;
  final String title;
  final String content;
  final DateTime submittedAt;

  const InquiryData({
    required this.userId,
    required this.title,
    required this.content,
    required this.submittedAt,
  });

  // Firestore 저장을 위한 toMap
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'isCompleted': false,
    };
  }
}