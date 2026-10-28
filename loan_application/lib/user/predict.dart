import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:loan_application/user/loan_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_languages.dart';

void main() {
  runApp(const LoanApp());
}

class LoanApp extends StatelessWidget {
  const LoanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sathapana Loan Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Padauk',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A4DA4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        cardTheme: const CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0A4DA4), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: const Color(0xFF0A4DA4),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0A4DA4), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
      home: const LoanFormScreen(),
    );
  }
}

class LoanFormScreen extends StatefulWidget {
  final int? categoryId;
  final String? selectedCategory;

  const LoanFormScreen({Key? key, this.categoryId, this.selectedCategory})
    : super(key: key);

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  int? _categoryId;
  @override
  void initState() {
    super.initState();
    print("Category ID = ${widget.categoryId}");
    print("Category Name = ${widget.selectedCategory}");

    _categoryId = widget.categoryId;
    if (widget.selectedCategory != null) {
      _selectedCategory = widget.selectedCategory;
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _termController = TextEditingController();

  String? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;
  Map<String, dynamic> _backendData = {};
  bool _hasCalculated = false;
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, List<Map<String, dynamic>>> subCategories = {
    "စိုက်ပျိုးရေးချေးငွေ": [
      {
        "name": "စိုက်ပျိုးရေးချေးငွေ (တစ်ဦးချင်း)",
        "rate": 28.0,
        "maxAmount": 20000000,
        "maxTerm": 24,
        "icon": Icons.agriculture,
        "color": const Color(0xFF2E7D32),
      },
      {
        "name": "စိုက်ပျိုးရေးချေးငွေ (ဝိုင်းကြီးချုပ်)",
        "rate": 28.0,
        "maxAmount": 3000000,
        "maxTerm": 12,
        "icon": Icons.groups,
        "color": const Color(0xFF388E3C),
      },
    ],
    "အသေးစားစီးပွားရေးလုပ်ငန်းချေးငွေ": [
      {
        "name": "အသေးစား စီးပွားရေးလုပ်ငန်းချေးငွေ (တစ်ဦးချင်း)",
        "rate": 28.0,
        "maxAmount": 20000000,
        "maxTerm": 24,
        "icon": Icons.storefront,
        "color": const Color(0xFF2E7D32),
      },
      {
        "name": "အသေးစား စီးပွားရေးလုပ်ငန်းချေးငွေ (ဝိုင်းကြီးချုပ်)",
        "rate": 28.0,
        "maxAmount": 3000000,
        "maxTerm": 12,
        "icon": Icons.handshake,
        "color": const Color(0xFF2E7D32),
      },
    ],
    "သုံးစွဲမှုချေးငွေ": [
      {
        "name":
            "အိမ်ရာပြုပြင်ခြင်းနှင့်လူသုံးကုန်ပစ္စည်းဝယ်ယူရေးချေးငွေ(တစ်ဦးချင်း)",
        "rate": 28.0,
        "maxAmount": 20000000,
        "maxTerm": 24,
        "icon": Icons.home_repair_service,
        "color": const Color(0xFF2E7D32),
      },
      {
        "name": "ပညာရေးနှင့်ကျန်းမာရေးဆိုင်ရာအရေးပေါ်ချေးငွေ(ဝိုင်းကြီးချုပ်)",
        "rate": 28.0,
        "maxAmount": 3000000,
        "maxTerm": 12,
        "icon": Icons.health_and_safety,
        "color": const Color(0xFF2E7D32),
      },
    ],
  };

  Future<String> _getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString(
      'userName',
    ); // 👈 Key Name ကို 'userName' ဟု ပြောင်းထားသည်

    if (savedUsername != null && savedUsername.isNotEmpty) {
      return savedUsername;
    } else {
      // 🎯 Login မဝင်ရသေးပါက သို့မဟုတ် Key မရှိပါက Testing အတွက် Default User ထည့်ပေးခြင်း
      print(
        "⚠️ [DEBUG] SharedPreferences ထဲတွင် Username မရှိသေးသဖြင့် Default User '' ကို သုံးပါမည်။",
      );
      return ""; // 👈 မိမိ စမ်းသပ်လိုသော DB ထဲက Username[cite: 6]
    }
  }

  // checkUserLoanStatus Function မရှိသေးပါက ဒီအတိုင်း ထည့်ပေးပါ
  Future<Map<String, dynamic>?> checkUserLoanStatus(String username) async {
    // မိမိ Django Backend API IP
    final url = Uri.parse(ApiConfig.userstatus + '$username/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('API Call Error: $e');
      return null;
    }
  }

  // _LoanFormScreenState Class ထဲတွင် ထည့်ရန်
  Future<void> _handleApplyLoan(String currentUsername) async {
    // ၁။ တွက်ချက်ထားခြင်း မရှိသေးရင် တားမြစ်မည်
    if (!_hasCalculated || _backendData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ကျေးဇူးပြု၍ ချေးငွေ အရင်တွက်ချက်ပေးပါ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ၂။ Loading Indicator ပြပေးခြင်း
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // ၃။ Django Backend API သို့ စစ်ဆေးရန် ခေါ်ယူခြင်း
    final result = await checkUserLoanStatus(currentUsername);

    // Loading ပိတ်မည်
    if (mounted) Navigator.pop(context);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server နှင့် ချိတ်ဆက်၍ မရပါ')),
      );
      return;
    }

    // ၄။ ❌ လျှောက်ထားခွင့် မရှိပါက (3 Months Remaining or 48H Cooldown) Dialog ဖြင့် တားမြစ်မည်[cite: 5]
    if (result['allow_apply'] == false) {
      String message = result['message'] ?? 'ထပ်မံ လျှောက်ထားခွင့် မရှိပါ။';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 8),
                Text("အသိပေးချက်"),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("လက်ခံသည်"),
              ),
            ],
          );
        },
      );
      return; // ရှေ့မသွားစေဘဲ ရပ်မည်[cite: 5]
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => LoanApplicationPage(
                categoryId: widget.categoryId ?? _categoryId ?? 1,
                categoryName:
                    widget.selectedCategory ?? _selectedCategory ?? "",
                amount: _amountController.text,
                term: _termController.text,
                backendData: _backendData,
              ),
        ),
      );
    }
  }

  Future<void> _calculateLoanOnBackend() async {
    if (!_formKey.currentState!.validate() || _selectedSubCategory == null) {
      if (_selectedSubCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ကျေးဇူးပြု၍ ချေးငွေအမျိုးအစား ရွေးချယ်ပါ'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasCalculated = false;
    });

    const String apiUrl = ApiConfig.calculate;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'amount': _amountController.text,
          'term': _termController.text,
          'rate': _selectedSubCategory!['rate'],
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _backendData = data;
          _hasCalculated = true;
        });
      } else {
        setState(() {
          _errorMessage =
              'Django backend error. Server returned code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection error. Make sure your Django server is running.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _termController.dispose();
    super.dispose();
  }

  String _formatter(dynamic amount) {
    if (amount == null) return "0";
    double numValue = double.parse(amount.toString());
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numValue
        .toStringAsFixed(0)
        .replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  Widget _buildResultRow(String label, dynamic amount, {Color? amountColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatter(amount)} MMK',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor ?? const Color(0xFF0A4DA4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A4DA4), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                // Container(
                //   padding: const EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     color: Colors.white.withOpacity(0.15),
                //     shape: BoxShape.circle,
                //   ),
                //   child: const Icon(
                //     Icons.calculate_rounded,
                //     color: Colors.white,
                //     size: 24,
                //   ),
                // ),
                // const SizedBox(height: 4),
                Text(
                  AppLanguage.text("Loan Calculator", "ချေးငွေတွက်ချက်ရန်"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            toolbarHeight: 100,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category Selection
                    if (widget.selectedCategory != null) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.category_rounded,
                              color: Color(0xFF0A4DA4),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLanguage.text(
                                      "Loan Category",
                                      "ချေးငွေအမျိုးအစား",
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedCategory ?? "",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: AppLanguage.text(
                              "Loan Category",
                              "ချေးငွေအမျိုးအစား",
                            ),
                            prefixIcon: const Icon(
                              Icons.category_rounded,
                              color: Color(0xFF0A4DA4),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          value: _selectedCategory,
                          items:
                              subCategories.keys.map((String category) {
                                final iconMap = {
                                  "စိုက်ပျိုးရေးချေးငွေ": Icons.agriculture,
                                  "အသေးစားစီးပွားရေးလုပ်ငန်းချေးငွေ":
                                      Icons.storefront,
                                  "သုံးစွဲမှုချေးငွေ": Icons.shopping_cart,
                                };
                                final colorMap = {
                                  "စိုက်ပျိုးရေးချေးငွေ": const Color(
                                    0xFF2E7D32,
                                  ),
                                  "အသေးစားစီးပွားရေးလုပ်ငန်းချေးငွေ":
                                      const Color(0xFFE65100),
                                  "သုံးစွဲမှုချေးငွေ": const Color(0xFF1565C0),
                                };

                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(
                                        iconMap[category] ?? Icons.category,
                                        size: 20,
                                        color: colorMap[category],
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        category,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                              _selectedSubCategory = null;
                              _amountController.clear();
                              _termController.clear();
                              _hasCalculated = false;
                              _errorMessage = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Sub Category Selection
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: InputDecoration(
                          labelText: AppLanguage.text(
                            "Loan Sub Category",
                            "ချေးငွေအမျိုးအစားခွဲ",
                          ),
                          prefixIcon: const Icon(
                            Icons.list_alt_rounded,
                            color: Color(0xFF0A4DA4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        value: _selectedSubCategory,
                        isExpanded: true,
                        items:
                            (subCategories[_selectedCategory] ?? []).map((
                              subCat,
                            ) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: subCat,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        subCat['name'],
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (Map<String, dynamic>? newValue) {
                          setState(() {
                            _selectedSubCategory = newValue;
                            _amountController.clear();
                            _termController.clear();
                            _hasCalculated = false;
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),

                    // Selected category chips
                    if (_selectedCategory != null &&
                        _selectedSubCategory != null) ...[
                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _selectedSubCategory!['icon'] ??
                                  Icons.attach_money,
                              color:
                                  _selectedSubCategory!['color'] ??
                                  Colors.green,
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                _selectedSubCategory!['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Loan Amount
                    // Loan Amount TextFormField နေရာကို အောက်ပါအတိုင်း အစားထိုးပါ
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          // 💡 Label ကို ပုံသေထားပြီး အရောင်မပြောင်းအောင် လုပ်ထားခြင်း
                          labelText: AppLanguage.text(
                            "Loan Amount (MMK)",
                            "ချေးငွေပမာဏ (ကျပ်)",
                          ),
                          labelStyle: const TextStyle(color: Colors.grey),

                          // 💡 အများဆုံးပမာဏကို အောက်တွင် helperText အနေဖြင့် ပြသခြင်း
                          helperText:
                              _selectedSubCategory != null
                                  ? AppLanguage.text(
                                    "Max: ${_formatter(_selectedSubCategory!["maxAmount"])} MMK",
                                    "အများဆုံး: ${_formatter(_selectedSubCategory!["maxAmount"])} ကျပ်",
                                  )
                                  : null,
                          helperStyle: const TextStyle(color: Colors.grey),

                          prefixIcon: const Icon(
                            Icons.attach_money_rounded,
                            color: Color(0xFF0A4DA4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ကျေးဇူးပြု၍ ချေးငွေပမာဏ ထည့်သွင်းပါ';
                          }
                          final inputAmount = double.tryParse(value);
                          if (inputAmount == null)
                            return 'နံပါတ်တစ်ခု ထည့်သွင်းပါ';

                          // 💡 ၅ သိန်းအောက်ဆိုရင် အောက်မှာ Error Message အနီရောင်ဖြင့် ပြပါမည်
                          if (inputAmount < 500000) {
                            return 'ချေးငွေအနည်းဆုံး ၅ သိန်း (500,000) ဖြစ်ရမည်';
                          } else if (_selectedSubCategory != null) {
                            double maxAllowed =
                                _selectedSubCategory!['maxAmount'].toDouble();
                            if (inputAmount > maxAllowed) {
                              return 'ဤချေးငွေအမျိုးအစားသည် အများဆုံး ${_formatter(maxAllowed)} ကျပ်သာ ခွင့်ပြုပါတယ်';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loan Term
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _termController,
                        decoration: InputDecoration(
                          labelText:
                              _selectedSubCategory == null
                                  ? AppLanguage.text(
                                    "Loan Term (Months)",
                                    "ချေးငွေသက်တမ်း (လ)",
                                  )
                                  : AppLanguage.text(
                                    "Loan Term (Maximum ${_selectedSubCategory!["maxTerm"]} Months)",
                                    "ချေးငွေသက်တမ်း (အများဆုံး ${_selectedSubCategory!["maxTerm"]} လ)",
                                  ),
                          prefixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF0A4DA4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'ကျေးဇူးပြု၍ ချေးငွေသက်တမ်း ထည့်သွင်းပါ';
                          final inputTerm = int.tryParse(value);
                          if (inputTerm == null)
                            return 'နံပါတ်တစ်ခု ထည့်သွင်းပါ';

                          if (_selectedSubCategory != null) {
                            int maxTermAllowed =
                                _selectedSubCategory!['maxTerm'];
                            if (inputTerm > maxTermAllowed) {
                              return 'ချေးငွေသက်တမ်း အများဆုံး $maxTermAllowed လသာ ခွင့်ပြုပါတယ်';
                            } else if (inputTerm < 0) {
                              return 'ချေးငွေသက်တမ်းအနည်းဆုံး (၁)လရှိရမည်';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Calculate Button
                    _isLoading
                        ? Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0A4DA4),
                              ),
                            ),
                          ),
                        )
                        : ElevatedButton(
                          onPressed: _calculateLoanOnBackend,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // const Icon(Icons.calculate_rounded, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                AppLanguage.text("Calculate", "တွက်ချက်မည်"),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 10),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Result Card
                    if (_hasCalculated) ...[
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0A4DA4), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A4DA4).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          margin: const EdgeInsets.all(1.5),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0A4DA4,
                                        ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.summarize_rounded,
                                        color: Color(0xFF0A4DA4),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppLanguage.text(
                                          "Calculation Result",
                                          "တွက်ချက်မှုရလဒ်",
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0A4DA4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, thickness: 1.5),

                                // Section 1: Fees
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.receipt_long_rounded,
                                            color: Colors.orange.shade700,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ထုတ်ယူချိန်တွင် ခုနှိမ်မည့် စရိတ်များ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      _buildResultRow(
                                        'ဝန်ဆောင်ခ (2%)',
                                        _backendData['service_fee'],
                                        amountColor: Colors.orange.shade700,
                                      ),
                                      _buildResultRow(
                                        'လူမှုဖူလုံရေးကြေး (0.5%)',
                                        _backendData['welfare_fee'],
                                        amountColor: Colors.orange.shade700,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.money_rounded,
                                              color: Colors.green.shade700,
                                              size: 18,
                                            ),

                                            const SizedBox(width: 6),

                                            Expanded(
                                              child: Text(
                                                'လက်ဝယ်ရရှိမည့်ငွေသားအစစ်',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            Flexible(
                                              child: Text(
                                                '${_formatter(_backendData['actual_disbursed'])} MMK',
                                                textAlign: TextAlign.right,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.green.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Section 2: Repayment
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.trending_up_rounded,
                                            color: Colors.blue.shade700,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ပြန်လည်ပေးဆပ်ရမည့် အခြေအနေ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      _buildResultRow(
                                        'စုစုပေါင်းကျသင့်မည့်အတိုး',
                                        _backendData['total_interest'],
                                        amountColor: Colors.blue.shade700,
                                      ),
                                      _buildResultRow(
                                        'စုစုပေါင်းပြန်ဆပ်ရမည့်ငွေ',
                                        _backendData['total_payable'],
                                        amountColor: Colors.blue.shade700,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0A4DA4,
                                          ).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              color: const Color(0xFF0A4DA4),
                                              size: 18,
                                            ),

                                            const SizedBox(width: 6),

                                            Expanded(
                                              child: Text(
                                                'ပျမ်းမျှလစဉ်ဆပ်ရမည့်ငွေ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            Flexible(
                                              child: Text(
                                                '${_formatter(_backendData['avg_monthly_payment'])} MMK',
                                                textAlign: TextAlign.right,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0A4DA4),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Note
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.grey.shade600,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                          'လျော့ကျလာသော အရင်းပေါ်အတိုးတွက်စနစ်ဖြစ်၍ ပထမလတွင် အများဆုံး ဆပ်ရမည်ဖြစ်ပြီး လစဉ်ဆပ်ရငွေ တဖြည်းဖြည်း လျော့နည်းသွားပါမည်။',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 💡 တွက်ချက်ထားခြင်း မရှိသေးပါက တားမြစ်မည်
                          if (!_hasCalculated || _backendData.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'ကျေးဇူးပြု၍ ချေးငွေ အရင်တွက်ချက်ပေးပါ',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          String currentUsername = await _getLoggedInUsername();

                          // 💡 Username ရရှိပါက API စစ်ဆေးပေးမည့် _handleApplyLoan ကို ခေါ်မည်
                          if (context.mounted) {
                            _handleApplyLoan(currentUsername);
                          }
                        },
                        // icon: const Icon(Icons.assignment_rounded),
                        label: Text(
                          AppLanguage.text(
                            "Apply for Loan",
                            "ချေးငွေလျှောက်ထားမည်",
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    // Extra bottom space for scrolling
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
