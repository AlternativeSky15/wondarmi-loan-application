// payment_request_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:loan_application/constant.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'app_languages.dart';

class PaymentRequestScreen extends StatefulWidget {
  final int listId;

  const PaymentRequestScreen({
    Key? key,
    required this.listId,
  }) : super(key: key);

  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // 🔗 Update this to your actual backend base URL
  final String apiUrl = ApiConfig.paymentrequest;

  final TextEditingController _loanIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _transactionIdController = TextEditingController();

  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = [
    'kbz_pay',
    'wave_pay',
    'aya_pay',

  ];

  final Map<String, String> _paymentMethodImages = {
    'kbz_pay': 'assets/image/kpay.jpg',
    'wave_pay': 'assets/image/wave.png',
    'aya_pay': 'assets/image/aya.png',
  };

  final Map<String, Color> _paymentMethodColors = {
    'kbz_pay': Color(0xFF4CAF50),
    'wave_pay': Color(0xFF2196F3),
    'aya_pay': Color(0xFFFF9800),

  };

  final Map<String, String> _paymentMethodLabels = {
    'kbz_pay': 'KBZ Pay',
    'wave_pay': 'Wave Pay',
    'aya_pay': 'AYA Pay',

  };

  DateTime? _transferDate;
  File? _paymentImage;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loanIdController.text = widget.listId.toString();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _paymentImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickTransferDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A6CF7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _transferDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _submitPaymentRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              "Please select a payment method",
              "ငွေပေးချေနည်း ရွေးချယ်ပါ။",
            ),
          ),
        ),
      );
      return;
    }



    if (_paymentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              "Please upload payment screenshot",
              "ငွေပေးချေမှု Screenshot တင်ပါ။",
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      final prefs = await SharedPreferences.getInstance();

      String? email = prefs.getString("email");

      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLanguage.text(
                "User email not found",
                "အသုံးပြုသူ Email မတွေ့ပါ။",
              ),
            ),
          ),
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      request.fields['email'] = email;
      request.fields['loan_id'] = _loanIdController.text.trim();
      request.fields['amount'] = _amountController.text.trim();
      request.fields['bank_account_or_phone'] = _bankAccountController.text.trim();
      request.fields['payment_method'] = _selectedPaymentMethod!;
      request.fields['transaction_id'] = _transactionIdController.text.trim();
      request.fields['transfer_date'] = _formatDate(_transferDate!);

      request.files.add(
        await http.MultipartFile.fromPath(
          'payment_image',
          _paymentImage!.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLanguage.text(
                "Payment submitted successfully.\nYour payment will be reviewed within 24 hours.",
                "ငွေဖြည့်သွင်းမှု အောင်မြင်ပါသည်။\nသင့်ငွေပေးချေမှုကို စစ်ဆေးပြီး 24 နာရီအတွင်း အကြောင်းကြားပါမည်။",
              ),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 5),
          ),
        );

        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppLanguage.text(
                "Submission failed",
                "တင်ပို့မှု မအောင်မြင်ပါ",
              )}: ${response.body}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppLanguage.text(
              "Error",
              "အမှား",
            )}: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _loanIdController.clear();
    _amountController.clear();
    _bankAccountController.clear();
    _transactionIdController.clear();
    setState(() {
      _selectedPaymentMethod = null;
      _transferDate = null;
      _paymentImage = null;
    });
  }

  @override
  void dispose() {
    _loanIdController.dispose();
    _amountController.dispose();
    _bankAccountController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          AppLanguage.text(
            "Payment Request",
            "ငွေပေးချေမှု တောင်းဆိုခြင်း",
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2332),
        elevation: 1,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4A6CF7),
                      Color(0xFF6B4CF7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A6CF7).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLanguage.text(
                        "Payment Details",
                        "ငွေပေးချေမှု အချက်အလက်",
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Loan #${widget.listId}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Loan ID (Read Only)
                    TextFormField(
                      controller: _loanIdController,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLanguage.text(
                          "Loan ID",
                          "ချေးငွေအမှတ်",
                        ),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A6CF7),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        prefixIcon: const Icon(
                          Icons.tag,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2332),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLanguage.text(
                            "Loan ID is required",
                            "ချေးငွေအမှတ် လိုအပ်သည်",
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppLanguage.text(
                          "Amount",
                          "ငွေပမာဏ",
                        ),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A6CF7),
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF6B7280),
                        ),
                        suffixText: "ကျပ်",
                        suffixStyle: const TextStyle(
                          color: Color(0xFF1A2332),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2332),
                      ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLanguage.text(
                              "Amount is required",
                              "ငွေပမာဏ ထည့်ပါ",
                            );
                          }

                          final input = value.trim();

                          // Numbers only (0-9) - no letters, spaces, or special characters
                          if (!RegExp(r'^\d+$').hasMatch(input)) {
                            return AppLanguage.text(
                              "Numbers only",
                              "ဂဏန်းသာ ထည့်ပါ",
                            );
                          }

                          final amount = double.parse(input);

                          if (amount <= 0) {
                            return AppLanguage.text(
                              "Amount must be greater than 0",
                              "ငွေပမာဏသည် 0 ထက်ကြီးရမည်",
                            );
                          }

                          if (amount > 999999999) {
                            return AppLanguage.text(
                              "Amount is too large",
                              "ငွေပမာဏ အလွန်များနေပါသည်",
                            );
                          }

                          return null;
                        }
                    ),
                    const SizedBox(height: 16),

                    // Bank Account / Phone
                    TextFormField(
                      controller: _bankAccountController,
                      decoration: InputDecoration(
                        labelText: AppLanguage.text(
                          "Bank Account / Phone",
                          "ဘဏ်အကောင့် / ဖုန်းနံပါတ်",
                        ),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A6CF7),
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.account_balance,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2332),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "ဖုန်းနံပါတ် သို့မဟုတ် Bank Account Number ဖြည့်ပါ";
                        }

                        String input = value.trim();
                        input = input.replaceAll(RegExp(r'[\s-]'), '');

                        // ============================
                        // Bank Account Number (10-16 digits)
                        // ============================
                        if (RegExp(r'^\d{10,16}$').hasMatch(input)) {
                          return null;
                        }

                        // ============================
                        // Myanmar Phone Number
                        // ============================

                        // ATOM
                        if (RegExp(r'^097\d{8}$').hasMatch(input)) {
                          return null;
                        }

                        // Ooredoo (099)
                        if (RegExp(r'^099\d{8}$').hasMatch(input)) {
                          return null;
                        }

                        // Mytel
                        if (RegExp(r'^096\d{8}$').hasMatch(input)) {
                          return null;
                        }

                        // MPT Mobile
                        if (RegExp(r'^09(2|4|5|8)\d{8}$').hasMatch(input)) {
                          return null;
                        }

                        // MPT Landline
                        if (RegExp(r'^01\d{7}$').hasMatch(input)) {
                          return null;
                        }

                        return "မြန်မာဖုန်းနံပါတ် သို့မဟုတ် Bank Account Number(10မှ16 လုံး)ကို မှန်ကန်စွာထည့်ပါ";
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: InputDecoration(
                        labelText: AppLanguage.text(
                          "Payment Method",
                          "ငွေပေးချေနည်း",
                        ),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A6CF7),
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.payment,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Row(
                            children: [
                              Image.asset(
                                _paymentMethodImages[method]!,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _paymentMethodLabels[method] ?? method,
                                style: const TextStyle(
                                  color: Color(0xFF1A2332),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLanguage.text(
                            "Please select a payment method",
                            "ငွေပေးချေနည်း ရွေးချယ်ပါ",
                          );
                        }
                        return null;
                      },

                    ),
                    const SizedBox(height: 16),

                    // Transaction ID
                    TextFormField(
                      controller: _transactionIdController,
                      decoration: InputDecoration(
                        labelText: AppLanguage.text(
                          "Transaction ID",
                          "ငွေလွှဲအမှတ်",
                        ),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A6CF7),
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.receipt,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2332),
                      ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLanguage.text(
                              "Transaction ID is required",
                              "ငွေလွှဲအမှတ် လိုအပ်သည်",
                            );
                          }

                          final id = value.trim();

                          if (id.length < 10) {
                            return AppLanguage.text(
                              "Transaction ID is too short",
                              "ငွေလွှဲအမှတ် မှားနေပါသည်",
                            );
                          }

                          if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
                            return AppLanguage.text(
                              "Invalid Transaction ID",
                              "ငွေလွှဲအမှတ် မှားနေပါသည်",
                            );
                          }

                          return null;
                        }
                    ),
                    const SizedBox(height: 16),

                    // Transfer Date
                    // Transfer Date
                    FormField<DateTime>(

                      initialValue: _transferDate,

                      validator: (value) {

                        if (_transferDate == null) {
                          return AppLanguage.text(
                            "Please select transfer date",
                            "ငွေလွှဲရက် ရွေးချယ်ပါ",
                          );
                        }


                        if (_transferDate!.isAfter(DateTime.now())) {
                          return AppLanguage.text(
                            "Transfer date cannot be in the future",
                            "ငွေလွှဲရက်သည် ယနေ့ထက် မကျော်ရပါ",
                          );
                        }


                        return null;
                      },


                      builder: (field) {

                        return InkWell(

                          onTap: () async {

                            await _pickTransferDate();

                            field.didChange(_transferDate);

                          },


                          child: InputDecorator(

                            decoration: InputDecoration(

                              labelText: AppLanguage.text(
                                "Transfer Date",
                                "ငွေလွှဲသည့်နေ့",
                              ),


                              errorText: field.errorText,


                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),


                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),


                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4A6CF7),
                                  width: 2,
                                ),
                              ),


                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF6B7280),
                              ),

                            ),


                            child: Row(

                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,


                              children: [

                                Text(

                                  _transferDate == null

                                      ? AppLanguage.text(
                                    "Select transfer date",
                                    "ငွေလွှဲရက် ရွေးချယ်ပါ",
                                  )

                                      : _formatDate(_transferDate!),


                                ),


                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF6B7280),
                                ),

                              ],

                            ),

                          ),

                        );

                      },

                    ),
                    const SizedBox(height: 16),

                    // Payment Screenshot Upload
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _paymentImage == null
                                ? const Color(0xFFE5E7EB)
                                : const Color(0xFF4CAF50),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _paymentImage == null
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFFF0FDF4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _paymentImage == null
                                  ? Icons.cloud_upload
                                  : Icons.check_circle,
                              color: _paymentImage == null
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF4CAF50),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _paymentImage == null
                                    ? AppLanguage.text(
                                  "Upload Payment Screenshot",
                                  "ငွေပေးချေမှု Screenshot တင်ပါ",
                                )
                                    : AppLanguage.text(
                                  "Screenshot uploaded successfully",
                                  "Screenshot တင်ပြီးပါပြီ",
                                ),
                                style: TextStyle(
                                  color: _paymentImage == null
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF1A2332),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_paymentImage != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _paymentImage = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_paymentImage != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _paymentImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPaymentRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFF4A6CF7).withOpacity(0.3),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      AppLanguage.text(
                        "Submit",
                        "တင်ပို့မည်",
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLanguage.text(
                  "Please ensure all information is correct before submitting",
                  "မတင်ပို့မီ အချက်အလက်အားလုံး မှန်ကန်ကြောင်း စစ်ဆေးပါ။",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}