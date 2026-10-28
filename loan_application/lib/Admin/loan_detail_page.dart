import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loan_application/constant.dart';

class LoanDetailView extends StatefulWidget {
  final int? loanId;
  const LoanDetailView({super.key, required this.loanId});

  @override
  State<LoanDetailView> createState() => _LoanDetailViewState();
}

class _LoanDetailViewState extends State<LoanDetailView> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFullDetail();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _monthController.dispose();
    super.dispose();
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

  Future<void> _fetchFullDetail() async {
    try {
      String url = ApiConfig.userloandetail + "${widget.loanId}/";

      // Ngrok Redirect CORS Error မတက်အောင် https သို့ Force ပြောင်းခြင်း
      if (url.startsWith('http://') && url.contains('ngrok')) {
        url = url.replaceFirst('http://', 'https://');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _detail = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
          _amountController.text =
              _detail!['amount_request']?.toString() ?? "0";
          _monthController.text = _detail!['month']?.toString() ?? "6";
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview(String action) async {
    if (_detail == null) return;

    if (_amountController.text.isEmpty || _monthController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ချေးငွေပမာဏနှင့် သက်တမ်းလကို ထည့်သွင်းပေးပါ"),
        ),
      );
      return;
    }

    try {
      String url = ApiConfig.saveloanhistory;
      if (url.startsWith('http://') && url.contains('ngrok')) {
        url = url.replaceFirst('http://', 'https://');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "user_id": _detail!['user_id'],
          "action": action,
          "amount_request": double.parse(_amountController.text),
          "month": int.parse(_monthController.text),
          "category_id": _detail!['category_id'] ?? 1,
        }),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final msg = responseData['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: action == 'approved' ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context);
      } else {
        String serverError =
            responseData['error'] ?? "သိမ်းဆည်းမှု မအောင်မြင်ပါ";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server Error: $serverError"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
    }
  }

  Widget _buildNRCImage(String? url, String label) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.indigo.shade900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          width: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade100.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            // 💡 Image.network အစား Safe ဖြစ်သည့် NgrokImage Widget ဖြင့် အစားထိုးထားသည်
            child:
                (url != null && url.isNotEmpty)
                    ? NgrokImage(imageString: url)
                    : _buildPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 100,
      width: 140,
      color: Colors.indigo.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, color: Colors.indigo.shade200, size: 30),
          const SizedBox(height: 5),
          Text(
            "No Image",
            style: TextStyle(color: Colors.indigo.shade200, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade100.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.indigo.shade600, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.indigo.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_detail == null)
      return const Scaffold(body: Center(child: Text("အချက်အလက်မတွေ့ရှိပါ")));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ချေးငွေလျှောက်လွှာ စိစစ်ခြင်း",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👈 ဘယ်ဘက် Column
            Expanded(
              child: Column(
                children: [
                  _buildModernCard("ကိုယ်ရေးအချက်အလက်", Icons.person_outline, [
                    _infoRow("အမည်", _detail!['full_name'] ?? "-"),
                    _infoRow(
                      "ဖုန်းနံပါတ်",
                      _detail!['phone_number'] != null &&
                              _detail!['phone_number'].toString().isNotEmpty
                          ? convertToMyanmarNumber(
                            _detail!['phone_number'].toString(),
                          )
                          : "-",
                    ),
                    _infoRow("နေရပ်လိပ်စာ", _detail!['address'] ?? "-"),
                    _infoRow(
                      "လျှောက်ထားသော ပမာဏ(ကျပ်)",
                      _detail!['amount_request'] != null
                          ? convertToMyanmarNumber(
                            NumberFormat('#,###').format(
                              num.tryParse(
                                    _detail!['amount_request']
                                        .toString()
                                        .replaceAll(',', ''),
                                  ) ??
                                  0,
                            ),
                          )
                          : "-",
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildModernCard(
                    "စာရွက်စာတမ်းများနှင့် ပုံများ",
                    Icons.description_outlined,
                    [
                      _infoRow("အလုပ်အကိုင်", _detail!['occupation'] ?? "-"),
                      _infoRow(
                        "ပျမ်းမျှဝင်ငွေ(ကျပ်)",
                        _detail!['income_average'] != null
                            ? convertToMyanmarNumber(
                              NumberFormat('#,###').format(
                                num.tryParse(
                                      _detail!['income_average']
                                          .toString()
                                          .replaceAll(',', ''),
                                    ) ??
                                    0,
                              ),
                            )
                            : "-",
                      ),
                      _infoRow(
                        "Bank Account",
                        _detail!['bank_account_phone'] != null &&
                                _detail!['bank_account_phone']
                                    .toString()
                                    .isNotEmpty
                            ? convertToMyanmarNumber(
                              _detail!['bank_account_phone'].toString(),
                            )
                            : "-",
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle("မှတ်ပုံတင် ပုံများ"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNRCImage(_detail!['nrc_photo_front'], "ရှေ့"),
                          _buildNRCImage(_detail!['nrc_photo_back'], "နောက်"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle("အိမ်ထောင်စုနှင့် ပိုင်ဆိုင်မှု"),
                      Wrap(
                        spacing: 15,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildNRCImage(
                            _detail!['household_list_photo_front'],
                            "အိမ်ထောင်စု (ရှေ့)",
                          ),
                          _buildNRCImage(
                            _detail!['household_list_photo_back'],
                            "အိမ်ထောင်စု (နောက်)",
                          ),
                          _buildNRCImage(
                            _detail!['ownership_image'],
                            "ပိုင်ဆိုင်မှု",
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // 👉 ညာဘက် Column
            Expanded(
              child: Column(
                children: [
                  _buildModernCard(
                    "အာမခံသူ (Guarantor)",
                    Icons.shield_outlined,
                    [
                      _infoRow("အမည်", _detail!['guarantor_name'] ?? "-"),
                      _infoRow(
                        "ဖုန်းနံပါတ်",
                        _detail!['guarantor_phone'] != null &&
                                _detail!['guarantor_phone']
                                    .toString()
                                    .isNotEmpty
                            ? convertToMyanmarNumber(
                              _detail!['guarantor_phone'].toString(),
                            )
                            : "-",
                      ),
                      _infoRow(
                        "နေရပ်လိပ်စာ",
                        _detail!['guarantor_address'] ?? "-",
                      ),
                      const SizedBox(height: 15),
                      _buildSectionTitle("အာမခံသူ မှတ်ပုံတင်ပုံများ"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNRCImage(_detail!['g_nrc_front'], "ရှေ့"),
                          _buildNRCImage(_detail!['g_nrc_back'], "နောက်"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.indigo.shade700,
        ),
      ),
    );
  }
}

// 💡 Ngrok / CORS / HTTP Redirect များကို ကျော်လွှား၍ ပုံဆွဲယူပေးသော Widget
class NgrokImage extends StatefulWidget {
  final String? imageString;

  const NgrokImage({super.key, required this.imageString});

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

    // 1️⃣ Base64 String စစ်ဆေးခြင်း
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

    // 💡 Ngrok CORS Redirect Error မတက်အောင် http:// ကို https:// သို့ Force ပြောင်းခြင်း
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    // 3️⃣ HTTP Request ဖြင့် ngrok Header ပါဝင်စွာ Bytes ဆွဲယူခြင်း
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
      return Container(
        color: Colors.indigo.shade50,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasError || _bytes == null) {
      return Container(
        color: Colors.indigo.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, color: Colors.indigo.shade200, size: 30),
            const SizedBox(height: 5),
            Text(
              "No Image",
              style: TextStyle(color: Colors.indigo.shade200, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Container(
            color: Colors.indigo.shade50,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.indigo.shade200,
              size: 30,
            ),
          ),
    );
  }
}
