import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:intl/intl.dart' as intl;
import 'package:excel/excel.dart' hide Border;
import 'package:audioplayers/audioplayers.dart';
// ملاحظة نسخة الويب: حزمة OneSignal الرسمية لا تدعم Flutter Web بنفس طريقة
// عمل الموبايل (تحتاج إعداد Service Worker + مفاتيح VAPID منفصلة)، لذلك يتم
// تفعيلها فقط على المنصات غير الويب لتفادي أي خطأ وقت التشغيل داخل المتصفح.
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'services/file_helper.dart';
import 'pages/match_management_page.dart';
import 'pages/participants_page.dart';
import 'pages/winners_page.dart';
import 'widgets/match_stats_panel.dart';

// -------------------------------------------------------------------------
// نظام LAVEORA | نسخة الإدارة - المنيو الذكي والتحكم الكامل
// -------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // نسخة الويب: لا نُفعّل OneSignal إطلاقًا لأنه غير مدعوم رسميًا على
  // Flutter Web بدون إعداد Service Worker منفصل (web/OneSignalSDKWorker.js
  // + مفتاح Web Push)، وتشغيله بدون هذا الإعداد يسبب أخطاء غير ضرورية في
  // لوحة الإدارة على المتصفح. على الموبايل/سطح المكتب يعمل بشكل طبيعي.
  if (!kIsWeb) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("80e9a120-0f85-4238-add0-92fa66c3a40c");
    OneSignal.Notifications.requestPermission(true);
  }

  runApp(const MyApp());
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

  static void playNotification() async {
    try {
      await _player.setReleaseMode(ReleaseMode.release);
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
            colors: [
              CafeTheme.primaryGold.withValues(alpha: 0.1),
              CafeTheme.darkBg,
            ],
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
            colors: [
              CafeTheme.primaryGold.withValues(alpha: 0.1),
              CafeTheme.darkBg,
            ],
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
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 40,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
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
                    var data = doc.data() as Map<String, dynamic>? ?? {};
                    String table = data['table_number']?.toString() ?? '؟';
                    String customer =
                        data['customer_name']?.toString() ?? 'مجهول';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ActionChip(
                        backgroundColor: CafeTheme.primaryGold,
                        label: Text(
                          "نداء: $customer | طاولة: ($table)",
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
        // تم إزالة _buildSummaryPanel() لتخفيف الضغط ومنع الشاشة الحمراء
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
                _isFirstLoad = false;
              }

              Map<String, List<QueryDocumentSnapshot>> customerGroups = {};
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>? ?? {};
                  String cName = (data['customer_name'] ?? "عميل خارجي")
                      .toString();
                  customerGroups.putIfAbsent(cName, () => []).add(doc);
                }
              }
              if (customerGroups.isEmpty) {
                return const Center(child: Text("لا توجد طلبات نشطة حالياً"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(10),
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
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (widget.orders.isEmpty) return;

      bool allReady = widget.orders.every(
        (doc) => ((doc.data() as Map?)?['status']?.toString() ?? "") == "جاهز",
      );
      if (allReady) {
        _timer?.cancel();
        return;
      }
      var oldest = widget.orders
          .map(
            (e) =>
                ((e.data() as Map?)?['timestamp'] as Timestamp?)?.toDate() ??
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
      var data = o.data() as Map<String, dynamic>? ?? {};
      await FirebaseFirestore.instance.collection('sales').add({
        'customer_name': data['customer_name'] ?? 'غير محدد',
        'table_number': data['table_number'] ?? 'غير محدد',
        'items': data['items'] ?? [],
        'items_with_qty': data['items_with_qty'] ?? [],
        'total': data['total'] ?? 0,
        'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
        'note': data['note'] ?? '',
        'phone': data['phone'] ?? '',
        'address': data['address'] ?? '',
      });
      await o.reference.delete();
    }
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) return const SizedBox.shrink();

    var firstOrderData =
        widget.orders.first.data() as Map<String, dynamic>? ?? {};
    bool allReady = widget.orders.every(
      (doc) => ((doc.data() as Map?)?['status']?.toString() ?? "") == "جاهز",
    );
    bool anyProcessing = widget.orders.any(
      (doc) =>
          ((doc.data() as Map?)?['status']?.toString() ?? "") == "جاري التجهيز",
    );
    var tableNum = firstOrderData['table_number']?.toString() ?? "خارجي";
    bool isExternal =
        tableNum == "خارجي" || tableNum == "null" || tableNum.isEmpty;

    String phone = firstOrderData['phone']?.toString() ?? "";
    String address = firstOrderData['address']?.toString() ?? "";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CafeTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isExternal
              ? Colors.blueAccent
              : (allReady
                    ? CafeTheme.accentGreen
                    : (anyProcessing
                          ? CafeTheme.accentOrange
                          : Colors.white10)),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CafeTheme.primaryGold,
                          ),
                        ),
                        Text(
                          isExternal ? "طلب خارجي 📦" : "طاولة رقم: $tableNum",
                          style: TextStyle(
                            fontSize: 11,
                            color: isExternal
                                ? Colors.blueAccent
                                : Colors.white54,
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
                  const SizedBox(width: 15),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: CafeTheme.primaryGold,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            if (isExternal && (phone.isNotEmpty || address.isNotEmpty))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                color: Colors.blueAccent.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (phone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 5),
                          SelectableText(
                            phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    if (address.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: SelectableText(
                              address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: widget.orders.map((o) {
                var data = o.data() as Map<String, dynamic>? ?? {};
                bool isReady = data['status'] == "جاهز";
                String note = data['note']?.toString() ?? "";
                List<Widget> itemWidgets = [];
                var rawItems = data['items_with_qty'] ?? data['items'];
                if (rawItems != null && rawItems is List) {
                  for (var item in rawItems) {
                    String displayText = (item is Map)
                        ? "${item['qty'] ?? 1} x ${item['name'] ?? 'صنف غير محدد'}"
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
                              if (((o.data() as Map?)?['status']?.toString() ??
                                      "") !=
                                  "جاهز") {
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
  Future<Map<String, double>> _calculateTrueSales(
    List<QueryDocumentSnapshot> salesDocs,
  ) async {
    double total = 0;
    var prodSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .get();
    Map<String, double> priceMap = {};
    for (var doc in prodSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>? ?? {};
      priceMap[data['name']?.toString() ?? ""] = (data['price'] ?? 0)
          .toDouble();
    }

    for (var doc in salesDocs) {
      var data = doc.data() as Map<String, dynamic>? ?? {};
      var items = data['items_with_qty'] ?? data['items'];

      if (items is List) {
        for (var item in items) {
          if (item is Map) {
            String name = item['name']?.toString() ?? "";
            int qty = int.tryParse(item['qty']?.toString() ?? "1") ?? 1;
            double price = priceMap[name] ?? 0;
            total += (price * qty);
          } else {
            String raw = item.toString();
            if (raw.contains('x')) {
              var parts = raw.split('x');
              int qty = int.tryParse(parts[0].trim()) ?? 1;
              String name = parts.last.trim();
              double price = priceMap[name] ?? 0;
              total += (price * qty);
            } else {
              double price = priceMap[raw] ?? 0;
              total += price;
            }
          }
        }
      }
    }
    return {'total': total};
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: CafeTheme.darkBg,
        appBar: AppBar(
          title: const Text("مكتب الإدارة 🖋️"),
          backgroundColor: CafeTheme.surface,
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: CafeTheme.primaryGold,
            tabs: [
              Tab(text: "الإحصائيات والتحكم"),
              Tab(text: "إدارة المنيو"),
              Tab(text: "إدارة المباريات"),
              Tab(text: "المشاركون"),
              Tab(text: "الفائزون"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatsTab(),
            _buildManagementTab(),
            const MatchManagementPage(),
            const ParticipantsPage(),
            const WinnersPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sales').snapshots(),
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snap.data?.docs ?? [];
        int orderCount = docs.length;

        return FutureBuilder<Map<String, double>>(
          future: _calculateTrueSales(docs),
          builder: (context, salesSnap) {
            double totalSales = salesSnap.data?['total'] ?? 0;

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
                const Text(
                  "إحصائيات توقعات المباريات ⚽",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CafeTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 12),
                const MatchStatsPanel(),
                const SizedBox(height: 30),
                const Text(
                  "إحصائيات المبيعات 💰",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CafeTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 12),
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
                        _categoryRankCard(docs),
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
                      () => _generateExcelReport(docs),
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
                      () => _showSalesLog(context, docs),
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
      },
    );
  }

  Widget _buildManagementTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(children: [UnifiedMenuManagement()]),
    );
  }

  Widget _categoryRankCard(List<QueryDocumentSnapshot> docs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CafeTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CafeTheme.primaryGold.withValues(alpha: 0.2),
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
      var pData = p.data() as Map<String, dynamic>? ?? {};
      itemToCat[pData['name']?.toString() ?? ""] =
          pData['cat']?.toString() ?? "غير مصنف";
    }
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>? ?? {};
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
          border: Border.all(color: col.withValues(alpha: 0.3), width: 1),
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
        color: isDanger
            ? Colors.red.withValues(alpha: 0.05)
            : CafeTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDanger
              ? Colors.red
              : CafeTheme.primaryGold.withValues(alpha: 0.2),
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

  Future<void> _generateExcelReport(List<QueryDocumentSnapshot> docs) async {
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
      TextCellValue('رقم الطاولة / خارجي'),
      TextCellValue('الأصناف والكميات'),
      TextCellValue('الإجمالي (جنيه)'),
      TextCellValue('الهاتف'),
      TextCellValue('العنوان'),
    ]);

    for (int i = 0; i < 8; i++) {
      var cell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }

    List<QueryDocumentSnapshot> sortedDocs = List.from(docs);
    sortedDocs.sort((a, b) {
      var aData = a.data() as Map<String, dynamic>? ?? {};
      var bData = b.data() as Map<String, dynamic>? ?? {};
      DateTime dtA = aData['timestamp'] != null
          ? (aData['timestamp'] as Timestamp).toDate()
          : DateTime.now();
      DateTime dtB = bData['timestamp'] != null
          ? (bData['timestamp'] as Timestamp).toDate()
          : DateTime.now();
      return dtB.compareTo(dtA);
    });

    for (var doc in sortedDocs) {
      var data = doc.data() as Map<String, dynamic>? ?? {};
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
        TextCellValue(data['table_number']?.toString() ?? 'خارجي'),
        TextCellValue(itemsStr),
        TextCellValue("${data['total'] ?? 0}"),
        TextCellValue(data['phone']?.toString() ?? '-'),
        TextCellValue(data['address']?.toString() ?? '-'),
      ]);
    }

    try {
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final fileName = "Laveora_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
        await saveExcelFile(fileBytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم تصدير التقرير بنجاح!"),
              backgroundColor: CafeTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving excel: $e");
    }
  }

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
      var pData = p.data() as Map<String, dynamic>? ?? {};
      itemPrices[pData['name']?.toString() ?? ""] = (pData['price'] ?? 0)
          .toDouble();
    }
    Map<String, Map<String, dynamic>> consolidatedItems = {};
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>? ?? {};
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
}

class UnifiedMenuManagement extends StatefulWidget {
  const UnifiedMenuManagement({super.key});
  @override
  State<UnifiedMenuManagement> createState() => _UnifiedMenuManagementState();
}

class _UnifiedMenuManagementState extends State<UnifiedMenuManagement> {
  final botCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  String _searchQuery = "";
  bool _showDuplicatesOnly = false;

  void _handleBotCommand() async {
    String txt = botCtrl.text.trim();
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
            .split(RegExp(r"[-،و]"))
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
        _msg("تم إضافة ${items.length} أصناف إلى قسم $finalCat بنجاح 🚀");
      } catch (e) {
        _msg(
          "لم أفهم الطلب جيداً، حاول قول: ضيف [صنف1 - صنف2] في قسم [الاسم] بسعر [الرقم]",
        );
      }
    }
    botCtrl.clear();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _editProduct(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>? ?? {};
    final nameEdit = TextEditingController(
      text: data['name']?.toString() ?? "",
    );
    final priceEdit = TextEditingController(
      text: (data['price'] ?? 0).toString(),
    );
    final catEdit = TextEditingController(text: data['cat']?.toString() ?? "");

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        title: const Text("تعديل الصنف"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEdit,
                decoration: const InputDecoration(labelText: "الاسم"),
              ),
              TextField(
                controller: priceEdit,
                decoration: const InputDecoration(labelText: "السعر"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: catEdit,
                decoration: const InputDecoration(labelText: "القسم"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              doc.reference.update({
                'name': nameEdit.text,
                'price': double.tryParse(priceEdit.text) ?? 0.0,
                'cat': catEdit.text,
              });
              Navigator.pop(d);
            },
            child: const Text("حفظ التعديل"),
          ),
        ],
      ),
    );
  }

  void _editCategory(DocumentSnapshot doc) {
    final catEdit = TextEditingController(
      text: ((doc.data() as Map?)?['name']?.toString() ?? ""),
    );
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: CafeTheme.surface,
        title: const Text("تعديل اسم القسم"),
        content: TextField(
          controller: catEdit,
          decoration: const InputDecoration(labelText: "اسم القسم الجديد"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              doc.reference.update({'name': catEdit.text});
              Navigator.pop(d);
            },
            child: const Text("تحديث"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: CafeTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CafeTheme.primaryGold.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.smart_toy_rounded, color: CafeTheme.primaryGold),
                  SizedBox(width: 10),
                  Text(
                    "بوت المنيو الذكي",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: botCtrl,
                decoration: InputDecoration(
                  hintText: "مثال: ضيف بيبسي و كولا في قسم المشروبات بسعر 20",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: CafeTheme.primaryGold),
                    onPressed: _handleBotCommand,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Row(
          children: [
            Icon(Icons.category, color: CafeTheme.primaryGold, size: 20),
            SizedBox(width: 10),
            Text(
              "الأقسام الحالية (تعديل بالضغط، حذف بالمطول):",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .snapshots(),
          builder: (c, snap) {
            if (!snap.hasData) return const SizedBox();
            return Wrap(
              spacing: 8,
              children: snap.data!.docs.map((doc) {
                String name =
                    ((doc.data() as Map?)?['name']?.toString() ?? "قسم");
                return GestureDetector(
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: const Text("حذف قسم"),
                        content: Text("هل تريد حذف قسم ($name)؟"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d),
                            child: const Text("إلغاء"),
                          ),
                          TextButton(
                            onPressed: () {
                              doc.reference.delete();
                              Navigator.pop(d);
                            },
                            child: const Text(
                              "حذف",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: ActionChip(
                    label: Text(name),
                    backgroundColor: CafeTheme.surface,
                    onPressed: () => _editCategory(doc),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "ابحث في المنيو...",
                  filled: true,
                  fillColor: CafeTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: "إظهار الأصناف المتكررة فقط",
              child: InkWell(
                onTap: () =>
                    setState(() => _showDuplicatesOnly = !_showDuplicatesOnly),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _showDuplicatesOnly
                        ? CafeTheme.accentOrange
                        : CafeTheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: CafeTheme.primaryGold),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    color: _showDuplicatesOnly ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showDuplicatesOnly)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "⚠️ يتم عرض الأصناف المكررة في المنيو فقط",
              style: TextStyle(color: CafeTheme.accentOrange, fontSize: 12),
            ),
          ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            var allDocs = snapshot.data!.docs;

            Map<String, int> nameCounts = {};
            for (var d in allDocs) {
              String name = ((d.data() as Map?)?['name']?.toString() ?? "")
                  .toLowerCase();
              nameCounts[name] = (nameCounts[name] ?? 0) + 1;
            }

            var filteredDocs = allDocs.where((d) {
              String name = ((d.data() as Map?)?['name']?.toString() ?? "")
                  .toLowerCase();
              bool matchesSearch = name.contains(_searchQuery.toLowerCase());
              if (_showDuplicatesOnly) {
                return matchesSearch && (nameCounts[name] ?? 0) > 1;
              }
              return matchesSearch;
            }).toList();

            return Container(
              decoration: BoxDecoration(
                color: CafeTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                separatorBuilder: (c, i) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  var item = filteredDocs[index];
                  var itemData = item.data() as Map<String, dynamic>? ?? {};
                  bool isDuplicate =
                      (nameCounts[itemData['name']?.toString().toLowerCase() ??
                              ""] ??
                          0) >
                      1;

                  return ListTile(
                    leading: isDuplicate
                        ? const Icon(
                            Icons.warning_amber_rounded,
                            color: CafeTheme.accentOrange,
                            size: 20,
                          )
                        : const Icon(
                            Icons.fastfood,
                            color: CafeTheme.primaryGold,
                            size: 20,
                          ),
                    title: Text(
                      itemData['name']?.toString() ?? "بدون اسم",
                      style: TextStyle(
                        color: isDuplicate
                            ? CafeTheme.accentOrange
                            : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "القسم: ${itemData['cat'] ?? 'بدون قسم'} | السعر: ${itemData['price'] ?? 0} ج.م",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editProduct(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (d) => AlertDialog(
                                title: const Text("حذف صنف"),
                                content: Text(
                                  "هل تريد حذف (${itemData['name'] ?? 'الصنف'}) من المنيو؟",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(d),
                                    child: const Text("إلغاء"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      item.reference.delete();
                                      Navigator.pop(d);
                                    },
                                    child: const Text(
                                      "تأكيد الحذف",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
}
