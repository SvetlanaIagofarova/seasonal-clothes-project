import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seasonalclothesproject/services/cloud/cloud_garment.dart';
import 'package:seasonalclothesproject/services/cloud/cloud_storage_constants.dart';
import 'package:seasonalclothesproject/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final garments = FirebaseFirestore.instance.collection('garments');

  Future<void> deleteGarment({required String documentId}) async {
    try {
      await garments.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteGarmentException();
    }
  }

  Future<void> updateGarment({
    required String documentId,
    required String text,
  }) async {
    try {
      await garments.doc(documentId).update({textFieldName: text});
    } catch (e) {
      throw CouldNotUpdateGarmentException();
    }
  }
  
  Stream<Iterable<CloudGarment>> allGarments({required String ownerUserId}) {
      final allGarments = garments
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .snapshots()
          .map((event) => event.docs
          .map((doc) => CloudGarment.fromSnapshot(doc)));
      return allGarments;
  }
  

  Future<CloudGarment> createNewGarment({required String ownerUserId}) async {
    final document = await garments.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });
    final fetchedGarment = await document.get();
    return CloudGarment(
      documentId: fetchedGarment.id,
      ownerUserId: ownerUserId,
      text: '',
    );
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
