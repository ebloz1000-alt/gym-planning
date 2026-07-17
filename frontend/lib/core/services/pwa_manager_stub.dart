class PwaManager {
  PwaManager();

  bool get available => false;
  void Function()? onChange;

  Future<bool> promptInstall() async => false;
}
