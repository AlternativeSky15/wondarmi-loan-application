import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

import 'package:loan_application/Admin/admin_seen_user.dart';
import 'package:loan_application/Admin/admin_summary_screen.dart';
import 'package:loan_application/Admin/documents-review-list.dart';
import 'package:loan_application/Admin/payment_schedule.dart';
import 'package:loan_application/constant.dart';
import 'admin_dashboard.dart';

class LoanCategoriesScreen extends StatefulWidget {
  const LoanCategoriesScreen({super.key});

  @override
  State<LoanCategoriesScreen> createState() => _LoanCategoriesScreenState();
}

class _LoanCategoriesScreenState extends State<LoanCategoriesScreen> {
  bool _isLoading = true;
  List<dynamic> _categories = [];
  int _selectedIndex = 1;

  final String _getApiUrl = ApiConfig.loan_categories;
  final String _baseCategoryUrl = ApiConfig.category;

  Uint8List? _selectedImageBytes;
  String? _imageBase64;

  final List<Color> _borderColors = [
    const Color(0xFF4CAF50),
    const Color(0xFF9C27B0),
    const Color(0xFF2196F3),
    const Color(0xFFFF9800),
    const Color(0xFF00BCD4),
    const Color(0xFFE91E63),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  String convertToMyanmarNumber(dynamic number) {
    String english = number.toString();
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const myanmarDigits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];

    String result = english;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(englishDigits[i], myanmarDigits[i]);
    }
    return result;
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoading = true);

      // Ngrok Redirect CORS Error မတက်အောင် https သို့ Force ပြောင်းခြင်း
      String fetchUrl = _getApiUrl;
      if (fetchUrl.contains('ngrok') && fetchUrl.startsWith('http://')) {
        fetchUrl = fetchUrl.replaceFirst('http://', 'https://');
      }

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _categories = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Categories Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _pickImage(StateSetter setDialogState) {
    if (kIsWeb) {
      final html.FileUploadInputElement input =
          html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      input.onChange.listen((event) {
        if (input.files!.isEmpty) return;

        final file = input.files!.first;
        final reader = html.FileReader();

        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          setDialogState(() {
            final fullBase64 = reader.result as String;
            _imageBase64 = fullBase64;

            if (fullBase64.contains(',')) {
              _selectedImageBytes = base64Decode(fullBase64.split(',')[1]);
            } else {
              _selectedImageBytes = base64Decode(fullBase64);
            }
          });
        });
      });
    }
  }

  Future<void> _saveCategory(
    int? id,
    String name,
    String type,
    String rate,
  ) async {
    String urlStr =
        id == null ? ApiConfig.add_category : "${ApiConfig.category}$id/";

    if (urlStr.contains('ngrok') && urlStr.startsWith('http://')) {
      urlStr = urlStr.replaceFirst('http://', 'https://');
    }

    final url = Uri.parse(urlStr);
    final method = id == null ? http.post : http.put;

    String sendBase64 = "";
    if (_imageBase64 != null) {
      if (_imageBase64!.contains(",")) {
        sendBase64 = _imageBase64!.split(",")[1];
      } else {
        sendBase64 = _imageBase64!;
      }
    }

    final response = await method(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "category_name": name,
        "category_type": type,
        "interest_rate": double.tryParse(rate) ?? 0.0,
        "image": sendBase64,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _imageBase64 = null;
        _selectedImageBytes = null;
      });
      _fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F43A2),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    _buildTopHeader(),
                    const SizedBox(height: 15),
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildDataTable(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5BB8),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  "assets/image/Logo2.PNG",
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) =>
                          const Icon(Icons.waves, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WONDAMI",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "ချေးငွေလုပ်ငန်း",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          _sidebarMenuItem(
            Icons.grid_view_rounded,
            "မူလစာမျက်နှာ",
            0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.layers_outlined,
            "ချေးငွေအမျိုးအစားများ",
            1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoanCategoriesScreen()),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.people_outline,
            "အသုံးပြုသူများ",
            2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.calendar_today_outlined,
            "ပြန်ဆပ်ရမည့်ငွေဇယား",
            3,
            onTap: () {
              setState(() => _selectedIndex = 3);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const RepaymentSchedulePage(),
                ),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.receipt_long_outlined,
            "ချေးငွေစာရွက်စာတမ်းစီစစ်ရန်",
            4,
            onTap: () {
              setState(() => _selectedIndex = 4);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDocumentReviewScreen(),
                ),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.insert_chart_outlined_rounded,
            "ငွေစာရင်းချုပ်",
            5,
            onTap: () {
              setState(() => _selectedIndex = 5);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminSummaryScreen()),
              );
            },
          ),
          const Spacer(),
          Opacity(
            opacity: 0.2,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarMenuItem(
    IconData icon,
    String title,
    int index, {
    required VoidCallback onTap,
  }) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "ချေးငွေအမျိုးအစားများ",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showDialog(),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: Text(
            "ချေးငွေအမျိုးအစားသစ်ထည့်ရန်",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF002984),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final item = _categories[index];
        Color itemColor = _borderColors[index % _borderColors.length];
        String catType = item['category_type']?.toString() ?? "General";

        // API Key ကွဲပြားမှုများကို စစ်ဆေးခြင်း
        String? imagePath =
            item['image'] ?? item['image_url'] ?? item['category_image'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: itemColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: NgrokImage(
                      imageString: imagePath?.toString(),
                      fallbackColor: itemColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['category_name'] ?? "N/A",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTagBadge(
                              "Active",
                              const Color(0xFF2E7D32),
                              const Color(0xFFE8F5E9),
                            ),
                            const SizedBox(width: 6),
                            _buildTagBadge(
                              catType,
                              itemColor,
                              itemColor.withOpacity(0.1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${convertToMyanmarNumber((double.tryParse(item['interest_rate']?.toString() ?? '0') ?? 0).toStringAsFixed(2))}%",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "အတိုးနှုန်း",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 25),
                Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF0F43A2),
                        ),
                        onPressed: () => _showDialog(item: item),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          String delUrl = "$_baseCategoryUrl${item['id']}/";
                          if (delUrl.contains('ngrok') &&
                              delUrl.startsWith('http://')) {
                            delUrl = delUrl.replaceFirst('http://', 'https://');
                          }
                          await http.delete(
                            Uri.parse(delUrl),
                            headers: {'ngrok-skip-browser-warning': 'true'},
                          );
                          _fetchCategories();
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showDialog({Map<String, dynamic>? item}) {
    final nCtrl = TextEditingController(text: item?['category_name'] ?? '');
    final tCtrl = TextEditingController(text: item?['category_type'] ?? '');
    final rCtrl = TextEditingController(
      text: item?['interest_rate']?.toString() ?? '',
    );

    _imageBase64 =
        item?['image'] ?? item?['image_url'] ?? item?['category_image'];
    _selectedImageBytes = null;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: 460,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item == null
                                ? "အမျိုးအစားအသစ်ထည့်ရန်"
                                : "အမျိုးအစားပြင်ဆင်ရန်",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(nCtrl, "ချေးငွေအမည်"),
                      const SizedBox(height: 12),
                      _buildTextField(tCtrl, "ချေးငွေအမျိုးအစား"),
                      const SizedBox(height: 12),
                      _buildTextField(rCtrl, "အတိုးနှုန်း (%)"),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _pickImage(setDialogState),
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1.5,
                            ),
                          ),
                          child:
                              _selectedImageBytes != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : (_imageBase64 != null &&
                                          _imageBase64!.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: NgrokImage(
                                          imageString: _imageBase64,
                                          fallbackColor: Colors.blue,
                                        ),
                                      )
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 40,
                                            color: Color(0xFF0F43A2),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "ပုံတင်ရန် ဤနေရာကို နှိပ်ပါ",
                                            style: TextStyle(
                                              color: Color(0xFF0F43A2),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "ပယ်ဖျက်မည်",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _saveCategory(
                                  item?['id'],
                                  nCtrl.text,
                                  tCtrl.text,
                                  rCtrl.text,
                                );
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF002984),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "သိမ်းဆည်းမည်",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}

// 💡 CORS / Redirect Error အားကျော်လွှားပြီး Ngrok Image ဆွဲယူပြသပေးသော Stateful Widget
class NgrokImage extends StatefulWidget {
  final String? imageString;
  final Color fallbackColor;

  const NgrokImage({
    super.key,
    required this.imageString,
    required this.fallbackColor,
  });

  @override
  State<NgrokImage> createState() => _NgrokImageState();
}

class _NgrokImageState extends State<NgrokImage> {
  Uint8List? _bytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant NgrokImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageString != widget.imageString) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final raw = widget.imageString;
    if (raw == null || raw.trim().isEmpty || raw == 'null') {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      return;
    }

    String imgData = raw.trim();

    // 1️⃣ Base64 String ဖြစ်ပါက တိုက်ရိုက် Decode လုပ်မည်
    if (imgData.startsWith('data:image') ||
        (!imgData.startsWith('http') && !imgData.contains('/'))) {
      try {
        String pureBase64 =
            imgData.contains(',') ? imgData.split(',')[1] : imgData;
        final decoded = base64Decode(pureBase64);
        if (mounted) {
          setState(() {
            _bytes = decoded;
            _isLoading = false;
            _hasError = false;
          });
        }
        return;
      } catch (e) {
        if (mounted)
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        return;
      }
    }

    // 2️⃣ URL Format ပြင်ဆင်ခြင်း
    String url = imgData;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      String baseUrl = ApiConfig.baseUrl;
      if (baseUrl.endsWith('/'))
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      if (!url.startsWith('/')) url = '/$url';
      url = '$baseUrl$url';
    }

    // 💡 အဓိကပြင်ဆင်ချက်: Ngrok Redirect (301 CORS Block) မဖြစ်စေရန် http:// ကို https:// သို့ အတင်းပြောင်းပေးပါမည်
    if (url.contains('ngrok') && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    // 3️⃣ HTTP Request ဖြင့် ngrok-skip-browser-warning ပါဝင်စွာ Image Bytes ဆွဲယူမည်
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _bytes = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        if (mounted)
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.fallbackColor,
          ),
        ),
      );
    }

    if (_hasError || _bytes == null) {
      return Icon(Icons.eco_outlined, color: widget.fallbackColor);
    }

    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Icon(Icons.eco_outlined, color: widget.fallbackColor),
    );
  }
}
