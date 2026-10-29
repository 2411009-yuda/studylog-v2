import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_viewmodel.dart';

/// Avatar bulat berisi foto profil (foto pilihan pengguna atau foto bawaan).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.radius = 40});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = context.watch<ProfileViewModel>().photoBytes;
    final ImageProvider image = bytes != null
        ? MemoryImage(bytes)
        : const AssetImage('assets/images/profile.png');

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      backgroundImage: image,
    );
  }
}
