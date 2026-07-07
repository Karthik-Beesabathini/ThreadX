import 'dart:math' as math;
import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final List<String> _players = [];
  final TextEditingController _nameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  double _lastRotation = 0.0;
  String _selectedPlayer = "";
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _calculateSelectedPlayer();
        setState(() {
          _isSpinning = false;
        });
      }
    });
  }

  void _spinBottle() {
    if (_isSpinning || _players.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _selectedPlayer = "";
    });

    final random = math.Random();
    double totalSpinsAngle = (5 + random.nextInt(4)) * 2 * math.pi;
    double randomFinalAngle = random.nextDouble() * 2 * math.pi;

    double targetAngle = _lastRotation + totalSpinsAngle + randomFinalAngle;

    _animation = Tween<double>(
      begin: _lastRotation % (2 * math.pi),
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    ));

    _lastRotation = targetAngle;
    _animationController.reset();
    _animationController.forward();
  }

  void _calculateSelectedPlayer() {
    if (_players.isEmpty) return;

    double theta = _animation.value % (2 * math.pi);
    if (theta < 0) theta += 2 * math.pi;

    double sectorWidth = (2 * math.pi) / _players.length;
    int targetIndex = (theta / sectorWidth).round() % _players.length;

    setState(() {
      _selectedPlayer = _players[targetIndex];
    });
  }

  void _addPlayer() {
    String name = _nameController.text.trim();
    if (name.isNotEmpty && _players.length < 12) {
      setState(() {
        _players.add(name);
      });
      _nameController.clear();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine a safe static diameter fallback for the wheelboard
    double screenWidth = MediaQuery.of(context).size.width;
    double wheelDiameter = screenWidth * 0.82;
    double radius = wheelDiameter / 2;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents resizing metrics changes at root level
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "SPIN THE BOTTLE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. CLEAN INPUT FIELD
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black87),
                    onSubmitted: (_) => _addPlayer(),
                    textInputAction: TextInputAction.done, // Closes keyboard gracefully on hit
                    decoration: InputDecoration(
                      hintText: "Enter player name...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addPlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Add",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // 2. PLAY WHEELBOARD WITH FIXED DIMENSIONS (FIXES CRUSHING BUG)
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Blocks scroll dragging lines
              child: Center(
                child: Container(
                  width: wheelDiameter,
                  height: wheelDiameter,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_players.isNotEmpty)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WheelLinePainter(playerCount: _players.length),
                          ),
                        ),

                      // Outer border ring
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                      ),

                      // Player labels
                      for (int i = 0; i < _players.length; i++)
                        Builder(
                          builder: (context) {
                            double angle = (i * 2 * math.pi / _players.length) - (math.pi / 2);
                            double x = radius * 0.72 * math.cos(angle);
                            double y = radius * 0.72 * math.sin(angle);
                            bool isPicked = _players[i] == _selectedPlayer;

                            return Transform.translate(
                              offset: Offset(x, y),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPicked ? Colors.black : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isPicked ? Colors.black : Colors.grey[200]!),
                                ),
                                child: Text(
                                  _players[i],
                                  style: TextStyle(
                                    color: isPicked ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // BOTTLE IMAGE POINTER
                      GestureDetector(
                        onTap: _spinBottle,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _animation.value,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/bootle.png',
                            width: 125,
                            height: 125,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. KABOOM TEXT BANNER
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  child: child,
                );
              },
              child: _selectedPlayer.isNotEmpty
                  ? Container(
                key: ValueKey(_selectedPlayer),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "💥 KABOOM! ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: "$_selectedPlayer's Turn",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : Text(
                _players.isEmpty ? "" : "Tap the bottle to spin!",
                key: const ValueKey("placeholder"),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _players.isNotEmpty
          ? Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton.small(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shape: CircleBorder(side: BorderSide(color: Colors.grey[200]!)),
          onPressed: () => setState(() {
            _players.clear();
            _selectedPlayer = "";
          }),
          child: const Icon(Icons.refresh, size: 18),
        ),
      )
          : null,
    );
  }
}

class WheelLinePainter extends CustomPainter {
  final int playerCount;
  WheelLinePainter({required this.playerCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (playerCount <= 1) return;

    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < playerCount; i++) {
      double angle = (i * 2 * math.pi / playerCount) - (math.pi / 2) + (math.pi / playerCount);
      final endpoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endpoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WheelLinePainter oldDelegate) {
    return oldDelegate.playerCount != playerCount;
  }
}