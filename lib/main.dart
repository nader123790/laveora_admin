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

class _UnifiedMenuManagementState extends State<UnifiedMenuManagement> {
  final catCtrl = TextEditingController();
  final prodName = TextEditingController();
  final prodPrice = TextEditingController();
  final prodImg = TextEditingController();

  final sizeTitle1 = TextEditingController(text: "صغير");
  final sizePrice1 = TextEditingController();
  final sizeTitle2 = TextEditingController(text: "وسط");
  final sizePrice2 = TextEditingController();
  final sizeTitle3 = TextEditingController(text: "كبير");
  final sizePrice3 = TextEditingController();

  String? selectedCat;
  bool useMultipleSizes = false;
  Set<String> selectedProducts = {};

  void _bulkDelete() async {
    if (selectedProducts.isEmpty) return;
    bool? confirm = await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        title: const Text("حذف جماعي"),
        content: Text("هل أنت متأكد من حذف ${selectedProducts.length} صنف؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text(
              "تأكيد الحذف",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (String id in selectedProducts) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(id)
            .delete();
      }
      setState(() => selectedProducts.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _card("إدارة الأقسام", [
          TextField(
            controller: catCtrl,
            decoration: const InputDecoration(hintText: "اسم القسم الجديد"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (catCtrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('categories').add({
                  'name': catCtrl.text,
                });
                catCtrl.clear();
              }
            },
            child: const Text("إضافة قسم"),
          ),
          const Divider(height: 30),
          const Text(
            "الأقسام الحالية (اضغط للحذف):",
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .snapshots(),
            builder: (c, snap) {
              if (!snap.hasData) return const SizedBox();
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: snap.data!.docs
                    .map(
                      (doc) => ActionChip(
                        label: Text((doc.data() as Map)['name']),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        avatar: const Icon(
                          Icons.delete_forever,
                          size: 16,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _confirmDelete(context, "القسم", doc.reference),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ]),
        const SizedBox(height: 20),
        _card("إضافة صنف جديد", [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .snapshots(),
            builder: (c, snap) => DropdownButtonFormField<String>(
              hint: const Text("اختار القسم"),
              items:
                  snap.data?.docs
                      .map(
                        (d) => DropdownMenuItem(
                          value: (d.data() as Map)['name'] as String,
                          child: Text((d.data() as Map)['name']),
                        ),
                      )
                      .toList() ??
                  [],
              onChanged: (v) => selectedCat = v,
            ),
          ),
          TextField(
            controller: prodName,
            decoration: const InputDecoration(hintText: "اسم الصنف"),
          ),
          TextField(
            controller: prodImg,
            decoration: const InputDecoration(
              hintText: "رابط الصورة (JPG/PNG)",
            ),
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text("استخدام أحجام متعددة (مثلاً: صغير/وسط/كبير)"),
            value: useMultipleSizes,
            onChanged: (v) => setState(() => useMultipleSizes = v),
            activeColor: CafeTheme.primaryGold,
          ),
          if (!useMultipleSizes)
            TextField(
              controller: prodPrice,
              decoration: const InputDecoration(hintText: "السعر الأساسي"),
              keyboardType: TextInputType.number,
            )
          else
            Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sizeTitle1,
                        decoration: const InputDecoration(labelText: "الحجم 1"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sizePrice1,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "السعر"),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sizeTitle2,
                        decoration: const InputDecoration(labelText: "الحجم 2"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sizePrice2,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "السعر"),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sizeTitle3,
                        decoration: const InputDecoration(labelText: "الحجم 3"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sizePrice3,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "السعر"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (prodName.text.isNotEmpty) {
                Map<String, dynamic> data = {
                  'name': prodName.text,
                  'image_url': prodImg.text,
                  'cat': selectedCat ?? "غير مصنف",
                  'has_sizes': useMultipleSizes,
                };
                if (useMultipleSizes) {
                  List<Map<String, dynamic>> sizes = [];
                  if (sizePrice1.text.isNotEmpty) {
                    sizes.add({
                      'name': sizeTitle1.text,
                      'price': double.tryParse(sizePrice1.text) ?? 0,
                    });
                  }
                  if (sizePrice2.text.isNotEmpty) {
                    sizes.add({
                      'name': sizeTitle2.text,
                      'price': double.tryParse(sizePrice2.text) ?? 0,
                    });
                  }
                  if (sizePrice3.text.isNotEmpty) {
                    sizes.add({
                      'name': sizeTitle3.text,
                      'price': double.tryParse(sizePrice3.text) ?? 0,
                    });
                  }
                  data['sizes'] = sizes;
                  data['price'] = sizes.isNotEmpty ? sizes[0]['price'] : 0.0;
                } else {
                  data['price'] = double.tryParse(prodPrice.text) ?? 0.0;
                }
                FirebaseFirestore.instance.collection('products').add(data);
                prodName.clear();
                prodPrice.clear();
                prodImg.clear();
                sizePrice1.clear();
                sizePrice2.clear();
                sizePrice3.clear();
              }
            },
            child: const Text("إضافة للمنيو"),
          ),
        ]),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "الأصناف المضافة حالياً 📋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CafeTheme.primaryGold,
              ),
            ),
            if (selectedProducts.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _bulkDelete,
                icon: const Icon(Icons.delete_sweep),
                label: Text("حذف المحدد (${selectedProducts.length})"),
              ),
          ],
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return Container(
              decoration: BoxDecoration(
                color: CafeTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (c, i) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  var item = snapshot.data!.docs[index];
                  var itemData = item.data() as Map;
                  bool isSelected = selectedProducts.contains(item.id);
                  String imgUrl = itemData['image_url'] ?? "";
                  bool hasSizes =
                      itemData.containsKey('has_sizes') &&
                      itemData['has_sizes'] == true;

                  return ListTile(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedProducts.remove(item.id);
                        } else {
                          selectedProducts.add(item.id);
                        }
                      });
                    },
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selectedProducts.add(item.id);
                              } else {
                                selectedProducts.remove(item.id);
                              }
                            });
                          },
                          activeColor: CafeTheme.primaryGold,
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black26,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imgUrl.isNotEmpty
                              ? Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.coffee,
                                  color: CafeTheme.primaryGold,
                                ),
                        ),
                      ],
                    ),
                    title: Text(itemData['name']),
                    subtitle: Text(
                      hasSizes ? "أحجام متعددة" : "القسم: ${itemData['cat']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${itemData['price']} ج.م",
                          style: const TextStyle(
                            color: CafeTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              _confirmDelete(context, "الصنف", item.reference),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext ctx, String type, DocumentReference ref) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        title: Text("حذف $type"),
        content: Text("هل أنت متأكد من حذف هذا ال$type؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              ref.delete();
              Navigator.pop(d);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
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
