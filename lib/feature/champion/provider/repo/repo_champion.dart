import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selfie_pick/core/data/collection.dart';

import '../../model/m_champion.dart';

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
  Future<List<ChampionModel>> fetchChampions(
      String region, String weekKey) async {
    try {
      final championDocId = '${region}_$weekKey';

      // 1. champions/채널_주차 문서 조회
      final docSnapshot = await _firestore
          .collection(MyCollection.CHAMPION)
          .doc(championDocId)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return [];
      }

      final data = docSnapshot.data()!;
      final List<ChampionModel> champions = [];

      // 2. 문서 내 rank1, rank2, rank3 필드 추출
      for (int i = 1; i <= 3; i++) {
        final rankData = data['rank$i'];

        if (rankData != null) {
          champions.add(ChampionModel.fromJson(rankData, data['weekKey']));
        }
      }

      return champions;
    } catch (e) {
      debugPrint('Error fetching champions: $e');
      throw Exception('챔피언 데이터를 불러오는 중 오류가 발생했습니다.');
    }
  }
}
