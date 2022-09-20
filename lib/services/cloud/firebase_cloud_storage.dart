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

  Stream<Iterable<CloudGarment>> allGarments({required String ownerUserId}) =>
      garments.snapshots().map((event) => event.docs
          .map((doc) => CloudGarment.fromSnapshot(doc))
          .where((garment) => garment.ownerUserId == ownerUserId));

  Future<Iterable<CloudGarment>> getGarments(
      {required String ownerUserId}) async {
    try {
      return await garments
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .get()
          .then(
            (value) => value.docs.map(
              (doc) {
                return CloudGarment(
                  documentId: doc.id,
                  ownerUserId: doc.data()[ownerUserIdFieldName] as String,
                  text: doc.data()[textFieldName] as String,
                );
              },
            ),
          );
    } catch (e) {
      throw CouldNotGetAllGarmentsException();
    }
  }

  void createNewGarment({required String ownerUserId}) async {
    await garments.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
