/// [HospitalEntity] mendefinisikan struktur data fundamental rumah sakit.
/// Kelas ini menggunakan constructor 'const' untuk efisiensi memori (immutability).
class HospitalEntity {
  final int? id;
  final String name;
  final String address; // Tambahkan field ini karena ada di JSON response
  final double latitude;
  final double longitude;
  final String phone;
  final String? description;
  final String? imageUrl; // Pastikan nama ini sinkron dengan model

  const HospitalEntity({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone, // Dibuat required untuk menghindari error 'null'
    this.description,
    this.imageUrl,
  });
}