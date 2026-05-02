import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:intl/intl.dart' as intl;
import 'package:excel/excel.dart' hide Border;
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// -------------------------------------------------------------------------
// نظام LAVEORA | نسخة الإدارة - المنهجية المطورة للتعامل مع الصوت (AudioPlayer)
// -------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA2FPHXlZetEjFCC9LQ-YDxr9VvTHFwa9I",
        authDomain: "harafy-app-f693e.firebaseapp.com",
        projectId: "harafy-app-f693e",
        storageBucket: "harafy-app-f693e.appspot.com",
        messagingSenderId: "29475261638",
        appId: "1:29475261638:web:adc4d1cb02b21de744e2ef",
      ),
    );
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }
  runApp(const LaveoraApp());
}

class CafeTheme {
  static const Color primaryGold = Color(0xFFC5A059);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF161616);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Colors.orangeAccent;
  static const Color accentRed = Color(0xFFE53935);
}

class AudioLinks {
  static const String notification = "https://files.catbox.moe/qyemgh.mp3";
  static const String cash =
      "https://www.myinstants.com/media/sounds/ka-ching.mp3";
}

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // تشغيل الصوت بطريقة تحافظ على الصوت حتى في الخلفية
  static void playNotification() async {
    try {
      await _player.play(UrlSource(AudioLinks.notification));
    } catch (e) {
      debugPrint("Play notification error: $e");
    }
  }

  static void playCash() async {
    try {
      await _player.play(UrlSource(AudioLinks.cash));
    } catch (e) {
      debugPrint("Play cash error: $e");
    }
  }

  // دالة فارغة كما طلبت لإلغاء الـ unlock التقليدي
  static void unlock() {
    // لا حاجة لهذه الدالة الآن
  }
}

Future<void> syncToGoogleSheets(Map<String, dynamic> data) async {
  const String webHookUrl = "YOUR_GOOGLE_SCRIPT_URL_HERE";
  try {
    await http.post(Uri.parse(webHookUrl), body: data);
  } catch (e) {
    debugPrint("Google Sheets Sync Error: $e");
  }
}

class LaveoraApp extends StatelessWidget {
  const LaveoraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "LAVEORA",
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: CafeTheme.darkBg,
        primaryColor: CafeTheme.primaryGold,
        cardTheme: CardThemeData(
          color: CafeTheme.cardBg,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [CafeTheme.primaryGold.withOpacity(0.1), CafeTheme.darkBg],
            radius: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 250,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.auto_awesome,
                  size: 100,
                  color: CafeTheme.primaryGold,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "LAVEORA",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: CafeTheme.primaryGold),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController passCtrl = TextEditingController();

  void login() async {
    var doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('admin_pass')
        .get();
    String correctPass = (doc.exists && doc.data() != null)
        ? doc['value'].toString()
        : "1234";

    if (passCtrl.text == correctPass) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => const Directionality(
            textDirection: TextDirection.rtl,
            child: CashierHomePage(),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "كلمة المرور غير صحيحة، يرجى المحاولة مرة أخرى",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [CafeTheme.primaryGold.withOpacity(0.1), CafeTheme.darkBg],
            radius: 1.2,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 80,
                  color: CafeTheme.primaryGold,
                ),
                const SizedBox(height: 15),
                const Text(
                  "LAVEORA",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "نظام إدارة الطلبات المحمي",
                  style: TextStyle(color: Colors.white54, letterSpacing: 1.2),
                ),
                const SizedBox(height: 50),
                Container(
                  width: 380,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: CafeTheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: CafeTheme.primaryGold,
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: CafeTheme.primaryGold),
                        ),
                        onPressed: () {
                          SoundManager.playNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تم اختبار نظام الصوت بنجاح ✅"),
                            ),
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text("اختبار نظام الصوت"),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 8,
                          color: CafeTheme.primaryGold,
                        ),
                        decoration: InputDecoration(
                          hintText: "••••",
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CafeTheme.primaryGold,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: login,
                        child: const Text("دخول للنظام"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({super.key});
  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> {
  void _goToAdmin(BuildContext context) async {
    final pass = TextEditingController();
    var doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('master_pass')
        .get();
    String correctMasterPass = (doc.exists)
        ? doc['value'].toString()
        : "LAVEORA_ADMIN";
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        title: const Text("دخول الإدارة 🔐"),
        content: TextField(
          controller: pass,
          obscureText: true,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: "أدخل كلمة مرور الإدارة"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (pass.text == correctMasterPass) {
                Navigator.pop(c);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const Directionality(
                      textDirection: TextDirection.rtl,
                      child: OwnerDashboard(),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("كلمة المرور غير صحيحة")),
                );
              }
            },
            child: const Text(
              "دخول",
              style: TextStyle(color: CafeTheme.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CafeTheme.surface,
        title: const Text(
          "LAVEORA - إدارة الطلبات",
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.admin_panel_settings_rounded,
              color: CafeTheme.primaryGold,
              size: 30,
            ),
            onPressed: () => _goToAdmin(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: const ActiveOrdersView(),
    );
  }
}

class ActiveOrdersView extends StatefulWidget {
  const ActiveOrdersView({super.key});
  @override
  State<ActiveOrdersView> createState() => _ActiveOrdersViewState();
}

class _ActiveOrdersViewState extends State<ActiveOrdersView> {
  int _lastOrderCount = 0;
  int _lastAlertCount = 0;
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              if (!_isFirstLoad &&
                  snapshot.data!.docs.length > _lastAlertCount) {
                SoundManager.playNotification();
              }
              _lastAlertCount = snapshot.data!.docs.length;
              return Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ActionChip(
                        backgroundColor: CafeTheme.primaryGold,
                        label: Text(
                          "نداء: ${data['customer_name'] ?? 'مجهول'} | طاولة: (${data['table_number'] ?? '?'})",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => doc.reference.delete(),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        _buildSummaryPanel(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                if (!_isFirstLoad &&
                    snapshot.data!.docs.length > _lastOrderCount) {
                  SoundManager.playNotification();
                }
                _lastOrderCount = snapshot.data!.docs.length;
              }
              _isFirstLoad = false;

              Map<String, List<QueryDocumentSnapshot>> customerGroups = {};
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String cName = (data['customer_name'] ?? "عميل خارجي")
                      .toString();
                  customerGroups.putIfAbsent(cName, () => []).add(doc);
                }
              }
              if (customerGroups.isEmpty) {
                return const Center(child: Text("لا توجد طلبات نشطة حالياً"));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.65,
                ),
                itemCount: customerGroups.length,
                itemBuilder: (c, i) => OrderCustomerCard(
                  customerName: customerGroups.keys.elementAt(i),
                  orders: customerGroups.values.elementAt(i),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPanel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        Map<String, int> summary = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'جاهز') continue;

          var items = data['items_with_qty'] ?? data['items'];
          if (items is List) {
            for (var item in items) {
              if (item is Map) {
                String name = item['name'] ?? '؟';
                int q = int.tryParse(item['qty'].toString()) ?? 1;
                summary[name] = (summary[name] ?? 0) + q;
              } else {
                String raw = item.toString();
                if (raw.contains('x')) {
                  var parts = raw.split('x');
                  int q = int.tryParse(parts[0].trim()) ?? 1;
                  String name = parts.last.trim();
                  summary[name] = (summary[name] ?? 0) + q;
                } else {
                  summary[raw] = (summary[raw] ?? 0) + 1;
                }
              }
            }
          }
        }

        if (summary.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: CafeTheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: CafeTheme.primaryGold.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.list_alt, color: CafeTheme.primaryGold, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "ملخص التحضير المطلوب (إجمالي الأصناف):",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CafeTheme.primaryGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: summary.entries
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          "${e.key} : ${e.value}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CafeTheme.accentOrange,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OrderCustomerCard extends StatefulWidget {
  final String customerName;
  final List<QueryDocumentSnapshot> orders;
  const OrderCustomerCard({
    super.key,
    required this.customerName,
    required this.orders,
  });
  @override
  State<OrderCustomerCard> createState() => _OrderCustomerCardState();
}

class _OrderCustomerCardState extends State<OrderCustomerCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      bool allReady = widget.orders.every(
        (doc) => (doc.data() as Map)['status'] == "جاهز",
      );
      if (allReady) {
        _timer?.cancel();
        return;
      }
      var oldest = widget.orders
          .map(
            (e) =>
                ((e.data() as Map)['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          )
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (mounted) setState(() => _elapsed = DateTime.now().difference(oldest));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setOrdersReady() async {
    for (var o in widget.orders) {
      await o.reference.update({'status': 'جاهز'});
    }
  }

  void _finalizeOrder() async {
    SoundManager.playCash();
    for (var o in widget.orders) {
      var data = o.data() as Map<String, dynamic>;
      await FirebaseFirestore.instance.collection('sales').add({
        'customer_name': data['customer_name'],
        'table_number': data['table_number'],
        'items': data['items'],
        'items_with_qty': data['items_with_qty'],
        'total': data['total'],
        'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
        'note': data['note'],
      });
      await o.reference.delete();
    }
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    bool allReady = widget.orders.every(
      (doc) => (doc.data() as Map)['status'] == "جاهز",
    );
    bool anyProcessing = widget.orders.any(
      (doc) => (doc.data() as Map)['status'] == "جاري التجهيز",
    );
    var tableNum = (widget.orders.first.data() as Map)['table_number'] ?? "؟";

    return Container(
      decoration: BoxDecoration(
        color: CafeTheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: allReady
              ? CafeTheme.accentGreen
              : (anyProcessing ? CafeTheme.accentOrange : Colors.white10),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CafeTheme.primaryGold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "طاولة رقم: $tableNum",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${_elapsed.inMinutes}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: allReady ? CafeTheme.accentGreen : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: widget.orders.map((o) {
                var data = o.data() as Map;
                bool isReady = data['status'] == "جاهز";
                String note = data['note'] ?? "";
                List<Widget> itemWidgets = [];
                var rawItems = data['items_with_qty'] ?? data['items'];
                if (rawItems != null && rawItems is List) {
                  for (var item in rawItems) {
                    String displayText = (item is Map)
                        ? "${item['qty']} x ${item['name']}"
                        : item.toString();
                    itemWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: isReady
                                  ? CafeTheme.accentGreen
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayText,
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: isReady
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isReady
                                      ? Colors.white38
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...itemWidgets,
                    if (note.isNotEmpty && note != "بدون إضافات")
                      Padding(
                        padding: const EdgeInsets.only(right: 24, bottom: 10),
                        child: Text(
                          "📝 $note",
                          style: const TextStyle(
                            fontSize: 12,
                            color: CafeTheme.accentOrange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          for (var o in widget.orders) {
                            if ((o.data() as Map)['status'] != "جاهز") {
                              o.reference.update({'status': 'جاري التجهيز'});
                            }
                          }
                        },
                        child: Text(anyProcessing ? "قيد التحضير" : "تجهيز"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allReady
                              ? Colors.grey
                              : CafeTheme.accentGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: allReady ? null : _setOrdersReady,
                        child: const Text("تم التجهيز ✅"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CafeTheme.primaryGold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _finalizeOrder,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text("تم الحساب 💰"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final TextEditingController rangeCtrl = TextEditingController(text: "20");
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRange();
  }

  void _loadCurrentRange() async {
    var doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('cafe_location')
        .get();
    if (doc.exists && (doc.data() as Map)['allowed_range'] != null) {
      setState(() {
        rangeCtrl.text = (doc.data() as Map)['allowed_range'].toString();
      });
    }
  }

  void _setCurrentLocation(BuildContext context) async {
    setState(() => _isLocating = true);
    try {
      final geolocation = html.window.navigator.geolocation;
      final pos = await geolocation.getCurrentPosition(
        enableHighAccuracy: true,
        timeout: const Duration(seconds: 10),
      );

      double lat = pos.coords?.latitude?.toDouble() ?? 0.0;
      double lon = pos.coords?.longitude?.toDouble() ?? 0.0;
      double range = double.tryParse(rangeCtrl.text) ?? 20.0;

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('cafe_location')
          .set({
            'lat': lat,
            'lon': lon,
            'allowed_range': range,
            'updated_at': FieldValue.serverTimestamp(),
          });

      if (mounted) setState(() => _isLocating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تثبيت الموقع بنطاق $range متر! ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: CafeTheme.surface,
          title: const Text("فشل تحديد الموقع ❌"),
          content: const Text(
            "تأكد من:\n1. تفعيل الـ GPS في جهازك.\n2. إعطاء المتصفح إذن الوصول للموقع.\n3. استخدام اتصال آمن (HTTPS).",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("فهمت"),
            ),
          ],
        ),
      );
    }
  }

  void _generateExcelReport(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return;
    var excel = Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'سجل مبيعات LAVEORA');
    Sheet sheetObject = excel['سجل مبيعات LAVEORA'];

    CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString("#C5A059"),
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
    );

    sheetObject.appendRow([
      TextCellValue('التاريخ'),
      TextCellValue('الوقت'),
      TextCellValue('اسم العميل'),
      TextCellValue('رقم الطاولة'),
      TextCellValue('الأصناف والكميات'),
      TextCellValue('الإجمالي (جنيه)'),
    ]);

    for (int i = 0; i < 6; i++) {
      var cell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }

    List<QueryDocumentSnapshot> sortedDocs = List.from(docs);
    sortedDocs.sort((a, b) {
      DateTime dtA = (a.data() as Map)['timestamp'] != null
          ? ((a.data() as Map)['timestamp'] as Timestamp).toDate()
          : DateTime.now();
      DateTime dtB = (b.data() as Map)['timestamp'] != null
          ? ((b.data() as Map)['timestamp'] as Timestamp).toDate()
          : DateTime.now();
      return dtB.compareTo(dtA);
    });

    for (var doc in sortedDocs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime dt =
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      String dateOnly = intl.DateFormat('yyyy-MM-dd').format(dt);
      String timeOnly = intl.DateFormat('hh:mm:ss a').format(dt);
      String itemsStr = "";
      if (data['items'] is List) {
        itemsStr = (data['items'] as List).join(' | ');
      }

      sheetObject.appendRow([
        TextCellValue(dateOnly),
        TextCellValue(timeOnly),
        TextCellValue(data['customer_name']?.toString() ?? 'بيع مباشر'),
        TextCellValue(data['table_number']?.toString() ?? '-'),
        TextCellValue(itemsStr),
        TextCellValue("${data['total']}"),
      ]);
    }

    var fileBytes = excel.encode();
    if (fileBytes != null) {
      final content = html.Blob([
        fileBytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(content);
      html.AnchorElement(href: url)
        ..setAttribute(
          "download",
          "LAVEORA_REPORT_${intl.DateFormat('yyyy_MM_dd').format(DateTime.now())}.xlsx",
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: CafeTheme.darkBg,
        appBar: AppBar(
          title: const Text("مكتب الإدارة 🖋️"),
          backgroundColor: CafeTheme.surface,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: CafeTheme.primaryGold,
            tabs: [
              Tab(text: "الإحصائيات والتحكم"),
              Tab(text: "إدارة المنيو والموقع"),
            ],
          ),
        ),
        body: TabBarView(children: [_buildStatsTab(), _buildManagementTab()]),
      ),
    );
  }

  Widget _buildStatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sales')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        double totalSales = 0;
        int orderCount = snap.data?.docs.length ?? 0;
        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            totalSales += (data['total'] ?? 0).toDouble();
          }
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "إحصائيات اليوم 📊",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CafeTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossCount = constraints.maxWidth > 900
                    ? 3
                    : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.8,
                  ),
                  children: [
                    _statCard(
                      "إجمالي المبيعات",
                      "${totalSales.toStringAsFixed(2)} ج.م",
                      Icons.payments,
                      Colors.greenAccent,
                    ),
                    _statCard(
                      "عدد الطلبات",
                      "$orderCount طلب",
                      Icons.shopping_basket,
                      Colors.blueAccent,
                    ),
                    _categoryRankCard(snap.data?.docs ?? []),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              "أدوات التحكم 🛠️",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CafeTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _adminTool(
                  context,
                  "تصدير سجل المبيعات (Excel)",
                  Icons.file_download,
                  () => _generateExcelReport(snap.data?.docs ?? []),
                ),
                _adminTool(
                  context,
                  "تغيير باسورد الإدارة",
                  Icons.security,
                  () => _showChangePassDialog(
                    context,
                    'master_pass',
                    'تغيير كلمة مرور المدير',
                  ),
                ),
                _adminTool(
                  context,
                  "تغيير باسورد الكاشير",
                  Icons.vpn_key,
                  () => _showChangePassDialog(
                    context,
                    'admin_pass',
                    'تغيير كلمة مرور الدخول',
                  ),
                ),
                _adminTool(
                  context,
                  "تغيير باسورد الويتر",
                  Icons.person_outline,
                  () => _showChangePassDialog(
                    context,
                    'waiter_pass',
                    'تغيير كلمة مرور الويتر (الزبائن)',
                  ),
                ),
                _adminTool(
                  context,
                  "سجل المبيعات المحلل",
                  Icons.analytics,
                  () => _showSalesLog(context, snap.data?.docs ?? []),
                ),
                _adminTool(
                  context,
                  "تصفير الحسابات",
                  Icons.refresh,
                  () => _clearSales(context),
                  isDanger: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _card("إعدادات الموقع الجغرافي 📍", [
            const Text(
              "تحديد موقع الكافية ونطاق السماح بالطلب للزبائن",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rangeCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: "نطاق السماح (بالمتر)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocating
                        ? Colors.grey
                        : CafeTheme.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _isLocating
                      ? null
                      : () => _setCurrentLocation(context),
                  icon: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isLocating ? "جاري التحديد..." : "تثبيت الموقع"),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),
          const UnifiedMenuManagement(),
        ],
      ),
    );
  }

  Widget _categoryRankCard(List<QueryDocumentSnapshot> docs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CafeTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CafeTheme.primaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard, color: CafeTheme.accentOrange, size: 18),
              SizedBox(width: 8),
              Text(
                "الأكثر طلباً (بالأقسام)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: FutureBuilder<List<MapEntry<String, int>>>(
              future: _getOrderedCategories(docs),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا توجد بيانات",
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                }
                return Scrollbar(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var entry = snapshot.data![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              "${index + 1}. ",
                              style: const TextStyle(
                                color: CafeTheme.primaryGold,
                                fontSize: 11,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "${entry.value}",
                              style: const TextStyle(
                                color: CafeTheme.accentOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<MapEntry<String, int>>> _getOrderedCategories(
    List<QueryDocumentSnapshot> docs,
  ) async {
    Map<String, int> catCounts = {};
    var prods = await FirebaseFirestore.instance.collection('products').get();
    Map<String, String> itemToCat = {};
    for (var p in prods.docs) {
      itemToCat[p['name']] = (p.data() as Map)['cat'] ?? "غير مصنف";
    }
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      List items = data['items'] is List ? data['items'] : [];
      for (var entry in items) {
        String name = entry.toString();
        int qty = 1;
        if (name.contains('x')) {
          var parts = name.split('x');
          qty = int.tryParse(parts[0].trim()) ?? 1;
          name = parts.last.trim();
        }
        String cat = itemToCat[name] ?? "أخرى";
        catCounts[cat] = (catCounts[cat] ?? 0) + qty;
      }
    }
    var sortedList = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedList;
  }

  Widget _statCard(String title, String val, IconData icon, Color col) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: CafeTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: col.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: col, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _adminTool(
    BuildContext ctx,
    String label,
    IconData icon,
    VoidCallback tap, {
    bool isDanger = false,
  }) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        color: isDanger ? Colors.red.withOpacity(0.05) : CafeTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDanger ? Colors.red : CafeTheme.primaryGold.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDanger ? Colors.red : CafeTheme.primaryGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDanger ? Colors.red : Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _msg(BuildContext ctx, String txt) => ScaffoldMessenger.of(
    ctx,
  ).showSnackBar(SnackBar(content: Text(txt, textAlign: TextAlign.center)));

  void _showChangePassDialog(BuildContext ctx, String docId, String title) {
    final c = TextEditingController();
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        title: Text(title),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            hintText: "أدخل كلمة المرور الجديدة",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              if (c.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('settings')
                    .doc(docId)
                    .set({'value': c.text});
                if (ctx.mounted) {
                  Navigator.pop(d);
                  _msg(ctx, "تم التحديث بنجاح ✅");
                }
              }
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _showSalesLog(BuildContext ctx, List<QueryDocumentSnapshot> docs) async {
    var prods = await FirebaseFirestore.instance.collection('products').get();
    Map<String, double> itemPrices = {};
    for (var p in prods.docs) {
      itemPrices[p['name']] = (p['price'] ?? 0).toDouble();
    }
    Map<String, Map<String, dynamic>> consolidatedItems = {};
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      List items = data['items'] is List ? data['items'] : [];
      for (var entry in items) {
        String raw = entry.toString();
        int qty = 1;
        String name = raw;
        if (raw.contains('x')) {
          var parts = raw.split('x');
          qty = int.tryParse(parts[0].trim()) ?? 1;
          name = parts[1].trim();
        }
        double pricePerUnit = itemPrices[name] ?? 0;
        if (consolidatedItems.containsKey(name)) {
          consolidatedItems[name]!['qty'] += qty;
          consolidatedItems[name]!['total'] += (qty * pricePerUnit);
        } else {
          consolidatedItems[name] = {'qty': qty, 'total': (qty * pricePerUnit)};
        }
      }
    }
    if (!ctx.mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: CafeTheme.darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (b) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "سجل المبيعات التفصيلي 📊",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CafeTheme.primaryGold,
              ),
            ),
            const Divider(height: 30),
            Expanded(
              child: ListView(
                children: [
                  if (consolidatedItems.isEmpty)
                    const Center(child: Text("لا توجد مبيعات مسجلة حالياً"))
                  else
                    ...consolidatedItems.entries.map(
                      (e) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.black26,
                            child: Text(
                              e.value['qty'].toString(),
                              style: const TextStyle(
                                color: CafeTheme.primaryGold,
                              ),
                            ),
                          ),
                          title: Text(e.key),
                          trailing: Text(
                            "${(e.value['total']).toStringAsFixed(2)} ج.م",
                            style: const TextStyle(
                              color: CafeTheme.accentGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSales(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        title: const Text("تأكيد تصفير الحسابات"),
        content: const Text("سيتم مسح جميع سجلات مبيعات اليوم، هل أنت متأكد؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              var docs = await FirebaseFirestore.instance
                  .collection('sales')
                  .get();
              for (var doc in docs.docs) {
                await doc.reference.delete();
              }
              if (ctx.mounted) {
                Navigator.pop(d);
                _msg(ctx, "تم تصفير السجلات بنجاح");
              }
            },
            child: const Text(
              "تأكيد المسح",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String t, List<Widget> c) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: CafeTheme.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Text(
          t,
          style: const TextStyle(
            color: CafeTheme.primaryGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...c,
      ],
    ),
  );
}

class UnifiedMenuManagement extends StatefulWidget {
  const UnifiedMenuManagement({super.key});
  @override
  State<UnifiedMenuManagement> createState() => _UnifiedMenuManagementState();
}

class _UnifiedMenuManagementState extends State<UnifiedMenuManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _newCatCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String? _selectedCatFilter;

  final _quickNameCtrl = TextEditingController();
  final _quickPriceCtrl = TextEditingController();
  String? _quickCat;

  final _botCtrl = TextEditingController();

  static const Map<String, List<Map<String, dynamic>>> _fullMenuData = {
    "الإسبريسو": [
      {"name": "اسبرسو سنجل", "price": 35.0},
      {"name": "اسبرسو دبل", "price": 45.0},
      {"name": "اسبرسو افوكادو", "price": 50.0},
      {"name": "ماكياتو", "price": 45.0},
      {"name": "كراميل ماكياتو", "price": 50.0},
      {"name": "كورتادو", "price": 50.0},
      {"name": "أمريكان كوفي", "price": 45.0},
      {"name": "لاتيه", "price": 50.0},
      {"name": "سبانش لاتيه", "price": 65.0},
      {"name": "فلات وايت", "price": 55.0},
      {"name": "كابتشينو", "price": 50.0},
      {"name": "موكا", "price": 55.0},
      {"name": "وايت موكا", "price": 55.0},
      {"name": "نسكافية", "price": 45.0},
      {"name": "نسكافية بلاك", "price": 35.0},
      {"name": "نسكافية نكهات(كراميل-بندق-شوكلت)", "price": 50.0},
    ],
    "القهوة تركي": [
      {"name": "قهوة تركي سينجل", "price": 30.0},
      {"name": "قهوة تركي دبل", "price": 45.0},
      {"name": "قهوة فرنساوي", "price": 35.0},
      {"name": "قهوة نكهات", "price": 40.0},
      {"name": "قهوة بالبندق", "price": 45.0},
    ],
    "المشروبات الساخنة": [
      {"name": "شاي", "price": 15.0},
      {"name": "شاي نكهات", "price": 20.0},
      {"name": "شاي أخضر", "price": 20.0},
      {"name": "شاي كرك", "price": 40.0},
      {"name": "براد شاي", "price": 25.0},
      {"name": "ينسون", "price": 20.0},
      {"name": "نعناع", "price": 20.0},
      {"name": "كركدية", "price": 20.0},
      {"name": "قرفة", "price": 20.0},
      {"name": "قرفة حليب", "price": 40.0},
      {"name": "هوت سيدر", "price": 40.0},
      {"name": "مكس اعشاب", "price": 25.0},
      {"name": "هوت شوكلت", "price": 50.0},
      {"name": "هوت أوريو", "price": 60.0},
      {"name": "هوت لوتس", "price": 60.0},
      {"name": "هوت بستاشيو", "price": 60.0},
      {"name": "سحلب", "price": 40.0},
      {"name": "سحلب مكسرات", "price": 50.0},
      {"name": "سحلب فواكه", "price": 60.0},
    ],
    "فرابتشينو": [
      {"name": "فرابتشينو كلاسيك", "price": 65.0},
      {"name": "فرابتشينو(كراميل-شوكلت-وايت شوكلت-لوتس-اوريو)", "price": 65.0},
      {"name": "فرابتشينو بيستاشيو", "price": 85.0},
    ],
    "العصائر الفريش": [
      {"name": "مانجو", "price": 60.0},
      {"name": "فراولة", "price": 60.0},
      {"name": "موز", "price": 60.0},
      {"name": "جوافة", "price": 60.0},
      {"name": "ليمون - ليمون نعناع", "price": 40.0},
      {"name": "برتقال", "price": 40.0},
      {"name": "موز حليب", "price": 70.0},
      {"name": "بلح", "price": 70.0},
      {"name": "كيوي", "price": 80.0},
      {"name": "افوكادو", "price": 85.0},
      {"name": "كوكتيل STORM", "price": 90.0},
      {"name": "فروت سلات", "price": 85.0},
    ],
    "إضافات للعصائر": [
      {"name": "حليب", "price": 15.0},
      {"name": "إضافة فليفر", "price": 10.0},
      {"name": "إضافة مكسرات", "price": 20.0},
      {"name": "نعناع اضافة", "price": 5.0},
      {"name": "بوبا", "price": 25.0},
    ],
    "سموزي": [
      {"name": "سموزي فراولة - مانجا - ليمون", "price": 65.0},
      {
        "name": "سموزي كيوي - اناناس - خوخ - بطيخ - باشن فروت - بلوبيري",
        "price": 60.0,
      },
      {"name": "سموزي STORM", "price": 75.0},
    ],
    "زبادي": [
      {"name": "زبادي عسل", "price": 65.0},
      {"name": "زبادي عسل مكسرات", "price": 75.0},
      {"name": "زبادي فراولة - مانجا - خوخ - بلوبيري", "price": 70.0},
      {"name": "زبادي مكس", "price": 75.0},
    ],
    "ديزرت": [
      {"name": "وافل نوتيلا - لوتس", "price": 75.0},
      {"name": "وافل كراميل شوكليت - وايت شوكلت", "price": 75.0},
      {"name": "وافل بستاشيو", "price": 80.0},
      {"name": "وافل كيندر", "price": 80.0},
      {"name": "وافل فروت", "price": 90.0},
      {"name": "وافل ميكس", "price": 100.0},
      {"name": "وافل STORM", "price": 110.0},
      {"name": "ميني بان كيك نوتيلا - لوتس", "price": 60.0},
      {"name": "ميني بان كراميل - شوكلت - وايت شوكليت", "price": 60.0},
      {"name": "ميني بان بستاشيو", "price": 60.0},
      {"name": "ميني بان كيندر", "price": 60.0},
      {"name": "ميني بان فروت", "price": 70.0},
      {"name": "ميني بان STORM", "price": 70.0},
      {"name": "تشيز كيك", "price": 75.0},
      {"name": "مولتن كيك", "price": 75.0},
      {"name": "طاجن وافل حسب اختيارك", "price": 85.0},
    ],
    "مشروبات غازية": [
      {"name": "مياه صغيرة", "price": 10.0},
      {"name": "مياه كبيرة", "price": 15.0},
      {"name": "كولا V", "price": 30.0},
      {"name": "بيبسي / سفن / ميرندا", "price": 30.0},
      {"name": "شويبس", "price": 30.0},
      {"name": "فيروز", "price": 30.0},
      {"name": "فولت / توست", "price": 35.0},
      {"name": "ريد بول", "price": 75.0},
    ],
    "ميلك شيك": [
      {"name": "ميلك شيك فانليا", "price": 75.0},
      {"name": "ميلك شيك شوكلت", "price": 75.0},
      {"name": "ميلك شيك كراميل", "price": 75.0},
      {"name": "ميلك شيك أوريو", "price": 75.0},
      {"name": "ميلك شيك لوتس", "price": 75.0},
      {"name": "ميلك شيك نوتيلا", "price": 75.0},
      {"name": "ميلك شيك بلوبري", "price": 75.0},
      {"name": "ميلك شيك روزبيري", "price": 75.0},
      {"name": "ميلك شيك ميكس بيري", "price": 75.0},
      {"name": "ميلك شيك باشن فروت", "price": 75.0},
      {"name": "ميلك شيك مانجا", "price": 75.0},
      {"name": "ميلك شيك فراولة", "price": 75.0},
      {"name": "ميلك شيك خوخ", "price": 75.0},
      {"name": "ميلك شيك بيستاشيو", "price": 85.0},
      {"name": "ميلك شيك سنيكرز", "price": 85.0},
      {"name": "ميلك شيك كيندر", "price": 85.0},
      {"name": "ميلك شيك STORM", "price": 110.0},
    ],
    "موهيتو": [
      {
        "name":
            "موهيتو (نعناع-بلوبري-روز بيري-مكس بيري-اناناس-بطيخ-فراولة-رمان-باشن فروت-كولا-مانجا-كيوي)",
        "price": 55.0,
      },
      {"name": "موهيتو ريد بول", "price": 90.0},
      {"name": "موهيتو هامر هيد", "price": 110.0},
      {"name": "سكاي بلو", "price": 65.0},
      {"name": "صن شاين", "price": 65.0},
      {"name": "صن رايز", "price": 65.0},
      {"name": "كيوي نعناع", "price": 60.0},
    ],
    "أيس كوفي": [
      {"name": "ايس لاتيه", "price": 60.0},
      {"name": "ايس سبانيش لاتيه", "price": 70.0},
      {"name": "ايس لاتيه كراميل", "price": 65.0},
      {"name": "ايس لاتيه فانليا", "price": 65.0},
      {"name": "ايس لاتيه (موكا - وايت)", "price": 65.0},
      {"name": "ايس كراميل مكياتو", "price": 65.0},
      {"name": "ايس امريكان كوفي", "price": 50.0},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newCatCtrl.dispose();
    _searchCtrl.dispose();
    _quickNameCtrl.dispose();
    _quickPriceCtrl.dispose();
    _botCtrl.dispose();
    super.dispose();
  }

  void _msg(String m, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: isError ? CafeTheme.accentRed : CafeTheme.accentGreen,
      ),
    );
  }

  void _importFullMenu() {
    int totalItems = _fullMenuData.values.fold(0, (s, l) => s + l.length);
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: CafeTheme.primaryGold),
            SizedBox(width: 10),
            Text("استيراد المنيو الكامل"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "سيتم رفع المنيو الكامل إلى النظام:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CafeTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_rounded,
                        color: CafeTheme.primaryGold,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${_fullMenuData.length} قسم",
                        style: const TextStyle(
                          color: CafeTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.fastfood_rounded,
                        color: CafeTheme.accentGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$totalItems صنف",
                        style: const TextStyle(
                          color: CafeTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "⚠️ الأقسام والأصناف الموجودة مسبقاً لن تتأثر",
              style: TextStyle(color: CafeTheme.accentOrange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CafeTheme.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(d);
              await _doImport();
            },
            icon: const Icon(Icons.rocket_launch_rounded, size: 16),
            label: const Text(
              "ابدأ الاستيراد",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doImport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (d) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: CafeTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: CafeTheme.primaryGold),
              const SizedBox(height: 20),
              const Text(
                "جاري رفع المنيو...",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                "${_fullMenuData.length} قسم • ${_fullMenuData.values.fold(0, (s, l) => s + l.length)} صنف",
                style: const TextStyle(
                  color: CafeTheme.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final db = FirebaseFirestore.instance;
      int addedCats = 0;
      int addedProds = 0;

      final existingCats = await db.collection('categories').get();
      final existingCatNames = existingCats.docs
          .map((d) => (d.data()['name'] ?? '').toString())
          .toSet();

      final existingProds = await db.collection('products').get();
      final existingProdNames = existingProds.docs
          .map((d) => (d.data()['name'] ?? '').toString().toLowerCase())
          .toSet();

      for (final entry in _fullMenuData.entries) {
        final catName = entry.key;
        final items = entry.value;

        if (!existingCatNames.contains(catName)) {
          await db.collection('categories').add({'name': catName});
          addedCats++;
        }

        for (final item in items) {
          final itemNameLower = (item['name'] as String).toLowerCase();
          if (!existingProdNames.contains(itemNameLower)) {
            await db.collection('products').add({
              'name': item['name'],
              'price': item['price'],
              'cat': catName,
              'image_url': '',
              'has_sizes': false,
            });
            addedProds++;
          }
        }
      }

      if (mounted) Navigator.pop(context);

      if (mounted) {
        int skipped =
            (_fullMenuData.length - addedCats) +
            (_fullMenuData.values.fold(0, (s, l) => s + l.length) - addedProds);
        showDialog(
          context: context,
          builder: (d) => AlertDialog(
            backgroundColor: CafeTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: CafeTheme.accentGreen),
                SizedBox(width: 10),
                Text("تم الاستيراد بنجاح! 🎉"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _resultRow("أقسام أُضيفت", "$addedCats", CafeTheme.primaryGold),
                const SizedBox(height: 8),
                _resultRow(
                  "أصناف أُضيفت",
                  "$addedProds",
                  CafeTheme.accentGreen,
                ),
                const SizedBox(height: 8),
                _resultRow("تم تخطيه (موجود)", "$skipped", Colors.white38),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CafeTheme.primaryGold,
                ),
                onPressed: () => Navigator.pop(d),
                child: const Text(
                  "ممتاز!",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _msg("حدث خطأ أثناء الاستيراد: $e", isError: true);
    }
  }

  Widget _resultRow(String label, String value, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _importFullMenu,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text(
              "استيراد المنيو الكامل (122 صنف / 13 قسم)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: CafeTheme.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CafeTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: CafeTheme.primaryGold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: CafeTheme.primaryGold,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _newCatCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "اسم القسم الجديد...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _addCategory(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("إضافة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CafeTheme.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: CafeTheme.primaryGold),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return _emptyState(
                Icons.category_outlined,
                "لا توجد أقسام بعد\nاضغط الزرار الذهبي لاستيراد المنيو كاملاً!",
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _categoryCard(docs[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _categoryCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name']?.toString() ?? "قسم";

    return Container(
      decoration: BoxDecoration(
        color: CafeTheme.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CafeTheme.primaryGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.folder_rounded,
            color: CafeTheme.primaryGold,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('cat', isEqualTo: name)
              .snapshots(),
          builder: (_, s) {
            int count = s.data?.docs.length ?? 0;
            return Text(
              "$count صنف",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBtn(
              Icons.edit_rounded,
              Colors.blueAccent,
              () => _editCategory(doc),
            ),
            const SizedBox(width: 4),
            _iconBtn(
              Icons.delete_rounded,
              CafeTheme.accentRed,
              () => _confirmDeleteCategory(doc, name),
            ),
          ],
        ),
      ),
    );
  }

  void _addCategory() async {
    final name = _newCatCtrl.text.trim();
    if (name.isEmpty) return;
    await FirebaseFirestore.instance.collection('categories').add({
      'name': name,
    });
    _newCatCtrl.clear();
    _msg("تم إضافة قسم: $name ✅");
  }

  void _editCategory(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ctrl = TextEditingController(text: data['name']?.toString() ?? "");
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "تعديل القسم",
          style: TextStyle(color: CafeTheme.primaryGold),
        ),
        content: _inputField(ctrl, "اسم القسم"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CafeTheme.primaryGold,
            ),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              doc.reference.update({'name': ctrl.text.trim()});
              Navigator.pop(d);
              _msg("تم تحديث اسم القسم ✅");
            },
            child: const Text("حفظ", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(DocumentSnapshot doc, String name) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: CafeTheme.accentRed),
            SizedBox(width: 8),
            Text("حذف قسم"),
          ],
        ),
        content: Text(
          "هل تريد حذف قسم «$name»؟\nلن يتم حذف أصناف القسم.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CafeTheme.accentRed,
            ),
            onPressed: () {
              doc.reference.delete();
              Navigator.pop(d);
              _msg("تم حذف القسم");
            },
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _quickAddCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CafeTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: CafeTheme.primaryGold,
                    ),
                    hintText: "بحث...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .snapshots(),
              builder: (_, snap) {
                final cats = [
                  'الكل',
                  ...?snap.data?.docs.map(
                    (d) => (d.data() as Map?)?['name']?.toString() ?? "",
                  ),
                ];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: CafeTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: CafeTheme.primaryGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCatFilter ?? 'الكل',
                      dropdownColor: CafeTheme.cardBg,
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(
                        Icons.filter_list,
                        color: CafeTheme.primaryGold,
                        size: 18,
                      ),
                      items: cats
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _selectedCatFilter = v == 'الكل' ? null : v,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: CafeTheme.primaryGold),
              );
            }

            var docs = snap.data!.docs.where((d) {
              final data = d.data() as Map<String, dynamic>? ?? {};
              final name = data['name']?.toString().toLowerCase() ?? "";
              final cat = data['cat']?.toString() ?? "";
              final matchSearch = name.contains(_searchQuery.toLowerCase());
              final matchCat =
                  _selectedCatFilter == null || cat == _selectedCatFilter;
              return matchSearch && matchCat;
            }).toList();

            if (docs.isEmpty) {
              return _emptyState(
                Icons.fastfood_rounded,
                "لا توجد أصناف\nأضف صنفك الأول من الأعلى!",
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _productCard(docs[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _quickAddCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CafeTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CafeTheme.primaryGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.add_shopping_cart,
                color: CafeTheme.primaryGold,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "إضافة صنف سريع",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _inputField(
                  _quickNameCtrl,
                  "اسم الصنف (أو اسم1، اسم2، ...)",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _inputField(_quickPriceCtrl, "السعر", isNumber: true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .snapshots(),
            builder: (_, snap) {
              final cats =
                  snap.data?.docs
                      .map((d) => (d.data() as Map?)?['name']?.toString() ?? "")
                      .toList() ??
                  [];
              if (cats.isEmpty) {
                return const Text(
                  "⚠️ أضف قسماً أولاً من تبويب الأقسام",
                  style: TextStyle(color: CafeTheme.accentOrange, fontSize: 12),
                );
              }
              if (!cats.contains(_quickCat)) _quickCat = cats.first;
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: CafeTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _quickCat,
                          dropdownColor: CafeTheme.cardBg,
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: CafeTheme.primaryGold,
                          ),
                          items: cats
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _quickCat = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _quickAddProduct,
                    icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: const Text("أضف"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CafeTheme.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          const Text(
            "💡 يمكنك إضافة أكثر من صنف دفعة واحدة: بيبسي، كولا، ماء",
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _quickAddProduct() async {
    final rawNames = _quickNameCtrl.text.trim();
    final cat = _quickCat;
    if (rawNames.isEmpty || cat == null) {
      _msg("أدخل اسم الصنف والقسم", isError: true);
      return;
    }
    double price = double.tryParse(_quickPriceCtrl.text.trim()) ?? 0.0;

    final names = rawNames
        .split(RegExp(r'[،,\-]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final name in names) {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'cat': cat,
        'price': price,
        'image_url': "",
        'has_sizes': false,
      });
    }
    _quickNameCtrl.clear();
    _quickPriceCtrl.clear();
    _msg("تم إضافة ${names.length} ${names.length == 1 ? 'صنف' : 'أصناف'} ✅");
  }

  Widget _productCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name']?.toString() ?? "بدون اسم";
    final cat = data['cat']?.toString() ?? "بدون قسم";
    final price = data['price'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: CafeTheme.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: CafeTheme.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.fastfood_rounded,
            color: CafeTheme.accentOrange,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            _chip(cat, CafeTheme.primaryGold),
            const SizedBox(width: 8),
            _chip("$price ج.م", CafeTheme.accentGreen),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBtn(
              Icons.edit_rounded,
              Colors.blueAccent,
              () => _editProduct(doc),
            ),
            const SizedBox(width: 4),
            _iconBtn(
              Icons.delete_rounded,
              CafeTheme.accentRed,
              () => _confirmDeleteProduct(doc, name),
            ),
          ],
        ),
      ),
    );
  }

  void _editProduct(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nameCtrl = TextEditingController(
      text: data['name']?.toString() ?? "",
    );
    final priceCtrl = TextEditingController(
      text: (data['price'] ?? 0).toString(),
    );
    String editCat = data['cat']?.toString() ?? "";

    showDialog(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: CafeTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: CafeTheme.primaryGold),
              SizedBox(width: 8),
              Text("تعديل الصنف"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inputField(nameCtrl, "اسم الصنف"),
                const SizedBox(height: 10),
                _inputField(priceCtrl, "السعر", isNumber: true),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .snapshots(),
                  builder: (_, snap) {
                    final cats =
                        snap.data?.docs
                            .map(
                              (d) =>
                                  (d.data() as Map?)?['name']?.toString() ?? "",
                            )
                            .toList() ??
                        [];
                    if (!cats.contains(editCat) && cats.isNotEmpty) {
                      editCat = cats.first;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: CafeTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: editCat.isEmpty ? null : editCat,
                          isExpanded: true,
                          dropdownColor: CafeTheme.cardBg,
                          style: const TextStyle(color: Colors.white),
                          hint: const Text(
                            "اختر القسم",
                            style: TextStyle(color: Colors.white54),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: CafeTheme.primaryGold,
                          ),
                          items: cats
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) => setSt(() => editCat = v ?? editCat),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text(
                "إلغاء",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CafeTheme.primaryGold,
              ),
              onPressed: () {
                doc.reference.update({
                  'name': nameCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  'cat': editCat,
                });
                Navigator.pop(d);
                _msg("تم تحديث الصنف ✅");
              },
              child: const Text("حفظ", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(DocumentSnapshot doc, String name) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: CafeTheme.accentRed),
            SizedBox(width: 8),
            Text("حذف صنف"),
          ],
        ),
        content: Text(
          "هل تريد حذف «$name»؟",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CafeTheme.accentRed,
            ),
            onPressed: () {
              doc.reference.delete();
              Navigator.pop(d);
              _msg("تم حذف الصنف");
            },
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBotTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CafeTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CafeTheme.primaryGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: CafeTheme.primaryGold),
              SizedBox(width: 8),
              Text(
                "بوت المنيو الذكي",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "اكتب أمر بالعربي وهيتنفذ تلقائياً",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _botCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "مثال: ضيف بيبسي وكولا في قسم المشروبات بسعر 20",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: CafeTheme.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: CafeTheme.primaryGold,
                ),
                onPressed: _handleBotCommand,
              ),
            ),
            onSubmitted: (_) => _handleBotCommand(),
          ),
          const SizedBox(height: 14),
          const Text(
            "أمثلة:",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...[
            "انشئ قسم الوجبات السريعة",
            "ضيف برجر في قسم الوجبات بسعر 50",
            "ضيف صنف بيبسي وكولا في قسم المشروبات بسعر 15",
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => setState(() => _botCtrl.text = e),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: CafeTheme.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: CafeTheme.primaryGold,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBotCommand() async {
    String txt = _botCtrl.text.trim();
    if (txt.isEmpty) return;

    if (txt.contains("انشئ قسم") || txt.contains("أنشئ قسم")) {
      String catName = txt.replaceAll(RegExp(r"انشئ قسم|أنشئ قسم"), "").trim();
      if (catName.isNotEmpty) {
        await FirebaseFirestore.instance.collection('categories').add({
          'name': catName,
        });
        _msg("تم إنشاء القسم: $catName ✅");
      }
    } else {
      try {
        String catPart = "";
        if (txt.contains("فى قسم"))
          catPart = txt.split("فى قسم")[1].trim();
        else if (txt.contains("في قسم"))
          catPart = txt.split("في قسم")[1].trim();
        else if (txt.contains("قسم"))
          catPart = txt.split("قسم")[1].trim();

        String pricePart = "";
        if (txt.contains("بسعر"))
          pricePart = txt.split("بسعر")[1].trim();
        else if (txt.contains("سعر"))
          pricePart = txt.split("سعر")[1].trim();

        String finalCat = catPart.split(RegExp(r"بسعر|سعر"))[0].trim();
        double finalPrice =
            double.tryParse(pricePart.replaceAll(RegExp(r"[^0-9.]"), "")) ??
            0.0;

        String itemsPart = "";
        if (txt.contains("صنف"))
          itemsPart = txt
              .split("صنف")[1]
              .split(RegExp(r"فى قسم|في قسم|قسم"))[0]
              .trim();
        else
          itemsPart = txt
              .split(RegExp(r"فى قسم|في قسم|قسم"))[0]
              .replaceAll(RegExp(r"اضف|أضف|ضيف"), "")
              .trim();

        List<String> items = itemsPart
            .split(RegExp(r"[-،و,]"))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (items.isEmpty || finalCat.isEmpty) throw Exception();

        for (var itemName in items) {
          await FirebaseFirestore.instance.collection('products').add({
            'name': itemName,
            'cat': finalCat,
            'price': finalPrice,
            'image_url': "",
            'has_sizes': false,
          });
        }
        _msg("تم إضافة ${items.length} أصناف إلى قسم $finalCat 🚀");
      } catch (e) {
        _msg(
          "لم أفهم الطلب، حاول: ضيف [اسم] في قسم [الاسم] بسعر [الرقم]",
          isError: true,
        );
      }
    }
    _botCtrl.clear();
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: CafeTheme.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            Icon(icon, color: Colors.white12, size: 60),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: CafeTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: CafeTheme.primaryGold,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_rounded, size: 16),
                    SizedBox(width: 6),
                    Text("الأقسام"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fastfood_rounded, size: 16),
                    SizedBox(width: 6),
                    Text("الأصناف"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 16),
                    SizedBox(width: 6),
                    Text("البوت"),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 950,
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(child: _buildCategoriesTab()),
              SingleChildScrollView(child: _buildProductsTab()),
              SingleChildScrollView(child: _buildBotTab()),
            ],
          ),
        ),
      ],
    );
  }
}

