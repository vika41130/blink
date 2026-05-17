class DissolveParticle {
  double x, y; // Vị trí hiện tại
  double vx, vy; // Vận tốc bay (véc-tơ hướng)
  double size; // Kích thước hạt vỡ
  double opacity = 1.0; // Độ mờ giảm dần khi bay xa

  DissolveParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  });

  // Cập nhật vị trí hạt sau mỗi khung hình
  void update() {
    x += vx;
    y += vy;
    opacity -= 0.02; // Tốc độ biến mất của hạt
    if (opacity < 0) opacity = 0;
  }
}
