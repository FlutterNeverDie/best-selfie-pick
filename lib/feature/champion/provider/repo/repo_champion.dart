import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/core/data/collection.dart';

import '../../../my_entry/model/m_entry.dart';

// Repository Provider 정의
final championRepoProvider = Provider((ref) => ChampionRepository(
  FirebaseFirestore.instance,
));

class ChampionRepository {
  final FirebaseFirestore _firestore;

  // 💡 V3.2: 챔피언 캐시 컬렉션을 사용합니다.

  ChampionRepository(this._firestore);

  /// 지난 회차의 최종 챔피언 목록 (Gold Pick)을 조회합니다.
  ///
  /// * 💡 Firebase Functions가 미리 정산하고 저장한 'champions' 컬렉션의
  /// * 단일 문서(Doc ID: ${region}_${weekKey})에서 1~3위 데이터를 가져옵니다.
  Future<List<EntryModel>> fetchChampions(String region, String weekKey) async {
    try {
      final championDocId = '${region}_$weekKey';

      // 1. champions/지역_주차 문서 조회
      final docSnapshot = await _firestore
          .collection(MyCollection.CHAMPION)
          .doc(championDocId)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return [];
      }

      final data = docSnapshot.data()!;
      final List<EntryModel> champions = [];

      // 2. 문서 내 rank1, rank2, rank3 필드 추출
      // 챔피언 탭에 필요한 핵심 데이터만 추출하여 EntryModel을 구성합니다.
      for (int i = 1; i <= 3; i++) {
        final rankData = data['rank$i'];

        if (rankData != null) {
          // EntryModel의 fromMap 생성자에 맞추어 Map을 구성합니다.
          champions.add(EntryModel.fromMap({
            // ContestEntry 모델과 필드 이름을 일치시키기 위해 명시적으로 매핑
            'entryId': rankData['entryId'],
            'userId': rankData['entryId'], // 편의상 entryId를 userId로 임시 사용
            'snsId': rankData['snsId'],
            'photoUrl': rankData['imageUrl'], // Cloud Function이 저장한 imageUrl 사용
            'thumbnailUrl': rankData['imageUrl'],
            'totalScore': rankData['totalScore'],
            'regionCity': rankData['regionCity'],
            'weekKey': data['weekKey'],
            'status': 'completed',
            'createdAt': Timestamp.now(), // 캐시 데이터이므로 현재 시각 사용
            'goldVotes': 0, 'silverVotes': 0, 'bronzeVotes': 0,
          }, rankData['entryId']));
        }
      }

      return champions;

    } catch (e) {
      debugPrint('Error fetching champions: $e');
      throw Exception('챔피언 데이터를 불러오는 중 오류가 발생했습니다.');
    }
  }
}