import 'package:cloud_firestore/cloud_firestore.dart';

class MenuUploader {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> uploadFullMenu() async {
    // 1. إضافة الأقسام أولاً
    List<String> categories = [
      "بيتزا إيطالي",
      "فطائر حادق",
      "فطائر حلو",
      "سندوتشات سوري",
      "باستا",
      "كريب لافيورا",
      "الهوت دوج",
      "مشروبات ساخنة",
      "عصائر فريش",
      "ميلك شيك",
      "وافل وبان كيك",
      "أيس كريم",
    ];

    for (var cat in categories) {
      await _db.collection('categories').doc(cat).set({'name': cat});
    }

    // 2. رفع الأصناف (نموذج شامل بناءً على الصور)

    // --- قسم البيتزا الإيطالي (بأحجام M, L, XL) ---
    await _addProductWithSizes("بيتزا ميكس جبنة", "بيتزا إيطالي", {
      "M": 135,
      "L": 165,
      "XL": 200,
    });
    await _addProductWithSizes("بيتزا مارجريتا", "بيتزا إيطالي", {
      "M": 110,
      "L": 140,
      "XL": 160,
    });
    await _addProductWithSizes("بيتزا سجق", "بيتزا إيطالي", {
      "M": 125,
      "L": 150,
      "XL": 170,
    });

    // --- قسم الفطائر الحادق (بأحجام L, XL) ---
    await _addProductWithSizes("فطير ميكس جبن", "فطير حادق", {
      "L": 170,
      "XL": 200,
    });
    await _addProductWithSizes("فطير سجق", "فطير حادق", {"L": 145, "XL": 180});

    // --- قسم السندوتشات السوري (سعر موحد) ---
    await _addSimpleProduct("سندوتش بطاطس", "سندوتشات سوري", 40);
    await _addSimpleProduct("سندوتش كبدة", "سندوتشات سوري", 50);
    await _addSimpleProduct("سندوتش استربس سوري", "سندوتشات سوري", 60);

    // --- قسم الباستا ---
    await _addSimpleProduct("باستا نيجرسكو", "باستا", 80);
    await _addSimpleProduct("باستا سجق", "باستا", 70);

    // --- قسم الكريب ---
    await _addSimpleProduct("كريب استربس", "كريب لافيورا", 100);
    await _addSimpleProduct("كريب ميكس فراخ", "كريب لافيورا", 110);
    await _addSimpleProduct("كريب نوتيلا", "كريب لافيورا", 65);

    // --- قسم المشروبات الساخنة ---
    await _addSimpleProduct("قهوة تركي سنجل", "مشروبات ساخنة", 25);
    await _addSimpleProduct("نسكافيه بلاك", "مشروبات ساخنة", 30);
    await _addSimpleProduct("سحلب مكسرات", "مشروبات ساخنة", 40);

    print("✅ تم رفع المنيو بنجاح إلى harafy-app-f693e");
  }

  // دالة للأصناف ذات السعر الموحد
  Future<void> _addSimpleProduct(String name, String cat, double price) async {
    await _db.collection('products').add({
      'name': name,
      'cat': cat,
      'price': price,
      'has_sizes': false,
      'image_url': "", // يمكنك إضافة روابط الصور لاحقاً
    });
  }

  // دالة للأصناف ذات الأحجام المتعددة (بيتزا/فطائر)
  Future<void> _addProductWithSizes(
    String name,
    String cat,
    Map<String, double> sizesMap,
  ) async {
    List<Map<String, dynamic>> sizes = [];
    sizesMap.forEach((key, value) {
      sizes.add({'name': key, 'price': value});
    });

    await _db.collection('products').add({
      'name': name,
      'cat': cat,
      'price': sizes[0]['price'], // السعر الابتدائي (الأصغر)
      'has_sizes': true,
      'sizes': sizes,
      'image_url': "",
    });
  }
}
