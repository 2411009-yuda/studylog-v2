/// Data mahasiswa. Immutable: perubahan dilakukan lewat [copyWith].
class Student {
  const Student({
    required this.nama,
    required this.nim,
    required this.programStudi,
    required this.status,
    required this.semester,
    required this.email,
    required this.portfolioUrl,
    required this.githubUrl,
  });

  final String nama;
  final String nim;
  final String programStudi;
  final String status;
  final int semester;
  final String email;
  final String portfolioUrl;
  final String githubUrl;

  Student copyWith({String? nama, String? programStudi}) {
    return Student(
      nama: nama ?? this.nama,
      nim: nim,
      programStudi: programStudi ?? this.programStudi,
      status: status,
      semester: semester,
      email: email,
      portfolioUrl: portfolioUrl,
      githubUrl: githubUrl,
    );
  }
}
