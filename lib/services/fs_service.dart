import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class FsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPublicacionesStream() {
    return _db
        .collection('publicaciones')
        .orderBy('fechaCreacion', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMisPublicacionesStream(String uid) {
    return _db
        .collection('publicaciones')
        .where('autorUid', isEqualTo: uid)
        .snapshots();
  }

  Future<QuerySnapshot> getCategorias() {
    return _db.collection('categoria').orderBy('nombre').get();
  }

  Future<void> crearPublicacion({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String categoria,
    required String lugar,
    required String fechaHora,
    required Uint8List fotoBytes,
    required String autorNombre,
    required String autorUid,
  }) {
    return _db.collection('publicaciones').add({
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'categoria': categoria,
      'lugar': lugar,
      'fechaHora': fechaHora,
      'foto': Blob(fotoBytes),
      'estado': 'Vigente',
      'autorNombre': autorNombre,
      'autorUid': autorUid,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> marcarComoDevuelto(String id) {
    return _db.collection('publicaciones').doc(id).update({
      'estado': 'Devuelto',
    });
  }

  Future<void> borrarPublicacion(String id) {
    return _db.collection('publicaciones').doc(id).delete();
  }
}