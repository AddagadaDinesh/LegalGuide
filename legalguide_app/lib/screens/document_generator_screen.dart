import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_strings.dart';
import '../services/locale_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/watermark_background.dart';

enum DocumentTemplateType {
  policeComplaint,
  rtiApplication,
  consumerNotice,
  unpaidDuesNotice,
}

class DocumentGeneratorScreen extends StatefulWidget {
  final DocumentTemplateType initialType;

  const DocumentGeneratorScreen({
    super.key,
    this.initialType = DocumentTemplateType.policeComplaint,
  });

  @override
  State<DocumentGeneratorScreen> createState() => _DocumentGeneratorScreenState();
}

class _DocumentGeneratorScreenState extends State<DocumentGeneratorScreen> {
  late DocumentTemplateType _selectedType;

  // Form Controllers
  final _senderNameController = TextEditingController();
  final _senderAddressController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientOrgController = TextEditingController();
  final _recipientAddressController = TextEditingController();
  final _incidentDateController = TextEditingController();
  final _incidentLocationController = TextEditingController();
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  final _demandController = TextEditingController();

  String _generatedText = '';
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _fillSampleData();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _senderNameController.dispose();
    _senderAddressController.dispose();
    _senderPhoneController.dispose();
    _recipientNameController.dispose();
    _recipientOrgController.dispose();
    _recipientAddressController.dispose();
    _incidentDateController.dispose();
    _incidentLocationController.dispose();
    _subjectController.dispose();
    _detailsController.dispose();
    _demandController.dispose();
    super.dispose();
  }

  void _fillSampleData() {
    switch (_selectedType) {
      case DocumentTemplateType.policeComplaint:
        _senderNameController.text = 'Rahul Sharma';
        _senderAddressController.text = 'Flat 402, Green Valley Apartments, Banjara Hills, Hyderabad';
        _senderPhoneController.text = '+91 98765 43210';
        _recipientNameController.text = 'The Station House Officer (SHO)';
        _recipientOrgController.text = 'Banjara Hills Police Station';
        _recipientAddressController.text = 'Road No. 12, Banjara Hills, Hyderabad - 500034';
        _incidentDateController.text = '25th September 2026 at approx 8:30 PM';
        _incidentLocationController.text = 'Near Metro Station Parking, Hyderabad';
        _subjectController.text = 'Complaint regarding theft of Mobile Phone and Wallet';
        _detailsController.text =
            'While returning home from office, two unidentified persons on a black motorcycle snatched my backpack containing an Apple iPhone 15 (IMEI: 356891234567890) and leather wallet containing Aadhar Card and SBI Debit Card. The perpetrators fled towards the main highway.';
        _demandController.text =
            'Kindly register an FIR under relevant provisions of the Bharatiya Nyaya Sanhita (BNS 2023), initiate investigation to recover stolen property, and issue an official acknowledged copy of this complaint.';
        break;

      case DocumentTemplateType.rtiApplication:
        _senderNameController.text = 'Priya Venkat';
        _senderAddressController.text = 'H.No 12-4-88, Gandhi Road, T. Nagar, Chennai - 600017';
        _senderPhoneController.text = '+91 94440 12345';
        _recipientNameController.text = 'The Public Information Officer (PIO)';
        _recipientOrgController.text = 'Greater Chennai Municipal Corporation';
        _recipientAddressController.text = 'Ripon Building, Chennai - 600003';
        _incidentDateController.text = 'Period: 1st January 2026 to 1st September 2026';
        _incidentLocationController.text = 'Ward No. 114, T. Nagar Area';
        _subjectController.text = 'Application for Information under Section 6(1) of the RTI Act, 2005';
        _detailsController.text =
            '1. Total budget allocated and expended for road repair and drainage maintenance in Ward 114 during the period.\n'
            '2. Name and contact details of the contractor awarded the road re-carpeting tender.\n'
            '3. Certified copy of the completion certificate and quality inspection report issued by the Municipal Engineer.';
        _demandController.text =
            'I have attached the statutory application fee of ₹10 via Indian Postal Order (IPO No: 45G 123456). Kindly provide the certified information within 30 days as prescribed by law.';
        break;

      case DocumentTemplateType.consumerNotice:
        _senderNameController.text = 'Vikram Kumar';
        _senderAddressController.text = 'B-12, Sector 62, Noida, Uttar Pradesh - 201301';
        _senderPhoneController.text = '+91 98111 22233';
        _recipientNameController.text = 'The Managing Director / Customer Care Head';
        _recipientOrgController.text = 'Apex Electronics Retail Pvt. Ltd.';
        _recipientAddressController.text = 'DLF Cyber City, Tower B, Gurugram, Haryana';
        _incidentDateController.text = '10th August 2026 (Invoice #APX-98214)';
        _incidentLocationController.text = 'Online Purchase via Official Portal';
        _subjectController.text = 'Legal Notice for Deficiency of Service & Replacement of Defective Refrigerator';
        _detailsController.text =
            'I purchased a double-door refrigerator (Model: APX-Cool 450L) for ₹42,500. Within 10 days of delivery, the compressor ceased functioning. Despite 4 separate technician visits and registered complaints (#CC-54321), the appliance has not been repaired or replaced, causing spoilage of food and immense mental agony.';
        _demandController.text =
            'You are hereby called upon to either replace the defective refrigerator with a brand new unit or refund the entire purchase price of ₹42,500 along with ₹10,000 towards damages within 15 days, failing which I shall approach the District Consumer Disputes Redressal Commission under Consumer Protection Act, 2019.';
        break;

      case DocumentTemplateType.unpaidDuesNotice:
        _senderNameController.text = 'Suresh Babu';
        _senderAddressController.text = 'Flat 201, Srinivasa Towers, Madhapur, Hyderabad - 500081';
        _senderPhoneController.text = '+91 99888 77665';
        _recipientNameController.text = 'The Managing Director';
        _recipientOrgController.text = 'Innovatech Solutions Pvt. Ltd.';
        _recipientAddressController.text = 'Hitec City, Phase 2, Hyderabad - 500081';
        _incidentDateController.text = 'Service Rendered between May 2026 and July 2026';
        _incidentLocationController.text = 'Contract Reference: IT-CON-2026/04';
        _subjectController.text = 'Legal Demand Notice for Immediate Payment of Outstanding Dues of ₹1,85,000';
        _detailsController.text =
            'I provided software consultancy services as per our signed service agreement. Three formal tax invoices (Inv #014, #018, #022) totaling ₹1,85,000 remain unpaid despite repeated email reminders dated 15th August, 30th August, and 10th September 2026.';
        _demandController.text =
            'Demand is hereby made for payment of ₹1,85,000 along with 18% p.a. interest within 15 days of this notice. Failure to comply will compel legal action including civil suit for recovery and criminal prosecution under Bharatiya Nyaya Sanhita (BNS) with full costs at your risk.';
        break;
    }
    _generateDocument();
  }

  void _generateDocument() {
    final today = DateTime.now();
    final dateStr = '${today.day}-${today.month}-${today.year}';

    final buffer = StringBuffer();

    if (_selectedType == DocumentTemplateType.rtiApplication) {
      buffer.writeln('APPLICATION FOR INFORMATION UNDER SECTION 6(1) OF THE RTI ACT, 2005');
      buffer.writeln('====================================================================\n');
      buffer.writeln('Date: $dateStr\n');
      buffer.writeln('To:');
      buffer.writeln(_recipientNameController.text.trim());
      buffer.writeln(_recipientOrgController.text.trim());
      buffer.writeln('${_recipientAddressController.text.trim()}\n');
      buffer.writeln('From:');
      buffer.writeln('Applicant: ${_senderNameController.text.trim()}');
      buffer.writeln('Address: ${_senderAddressController.text.trim()}');
      buffer.writeln('Contact Number: ${_senderPhoneController.text.trim()}\n');
      buffer.writeln('SUBJECT: ${_subjectController.text.trim()}\n');
      buffer.writeln('Sir / Madam,\n');
      buffer.writeln('I am a citizen of India and require the following information under the Right to Information Act, 2005:');
      buffer.writeln('\nPARTICULARS OF INFORMATION SOUGHT:');
      buffer.writeln('${_detailsController.text.trim()}\n');
      buffer.writeln('RELEVANT PERIOD / JURISDICTION:');
      buffer.writeln('${_incidentDateController.text.trim()} | ${_incidentLocationController.text.trim()}\n');
      buffer.writeln('FEE DETAILS & DECLARATION:');
      buffer.writeln(_demandController.text.trim());
      buffer.writeln('\nI state that the information sought does not fall within the exemptions contained in Section 8 or 9 of the RTI Act and pertains to public interest.\n');
      buffer.writeln('Yours faithfully,\n\n');
      buffer.writeln('(${_senderNameController.text.trim()})');
      buffer.writeln('Applicant Signature');
    } else {
      buffer.writeln(_selectedType == DocumentTemplateType.policeComplaint
          ? 'FORMAL POLICE COMPLAINT / FIRST INFORMATION INTIMATION'
          : 'FORMAL LEGAL DEMAND NOTICE');
      buffer.writeln('==========================================================\n');
      buffer.writeln('Date: $dateStr\n');
      buffer.writeln('TO:');
      buffer.writeln(_recipientNameController.text.trim());
      buffer.writeln(_recipientOrgController.text.trim());
      buffer.writeln('${_recipientAddressController.text.trim()}\n');
      buffer.writeln('FROM:');
      buffer.writeln(_senderNameController.text.trim());
      buffer.writeln(_senderAddressController.text.trim());
      buffer.writeln('Phone: ${_senderPhoneController.text.trim()}\n');
      buffer.writeln('SUBJECT: ${_subjectController.text.trim()}\n');
      buffer.writeln('Respected Sir/Madam,\n');
      buffer.writeln('I, the undersigned, submit the following facts for your immediate notice and necessary action:\n');
      buffer.writeln('1. STATEMENT OF INCIDENT / FACTS:');
      buffer.writeln('${_detailsController.text.trim()}\n');
      buffer.writeln('2. DATE, TIME & LOCATION:');
      buffer.writeln('Date/Time: ${_incidentDateController.text.trim()}');
      buffer.writeln('Location: ${_incidentLocationController.text.trim()}\n');
      buffer.writeln('3. RELIEF / ACTION DEMANDED:');
      buffer.writeln('${_demandController.text.trim()}\n');
      buffer.writeln('Kindly treat this as an urgent matter and provide written acknowledgment.\n\n');
      buffer.writeln('Sincerely,\n\n');
      buffer.writeln('(${_senderNameController.text.trim()})');
      buffer.writeln('Signature / Complainant');
    }

    setState(() {
      _generatedText = buffer.toString();
    });
  }

  Future<void> _copyToClipboard() async {
    _generateDocument();
    await Clipboard.setData(ClipboardData(text: _generatedText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Document copied to clipboard! Ready to paste or print.')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareViaEmail() async {
    _generateDocument();
    final subject = Uri.encodeComponent(_subjectController.text.trim());
    final body = Uri.encodeComponent(_generatedText);
    final mailUrl = 'mailto:?subject=$subject&body=$body';
    final uri = Uri.parse(mailUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyToClipboard();
    }
  }

  void _toggleTts() {
    _generateDocument();
    TtsService.instance.toggle(
      text: _generatedText,
      id: 'doc_generator_preview',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTe = LocaleService.isTelugu;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTe ? 'చట్టపరమైన పత్రాల జనరేటర్' : tr('Legal Document Generator'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isTe ? 'పూర్తి టెంప్లేట్ ఫిల్ చేయండి & కాపీ చేయండి' : tr('Instant Draft, Copy & Share'),
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_previewMode ? Icons.edit_note_rounded : Icons.visibility_rounded, color: AppColors.accent),
            tooltip: _previewMode ? tr('Edit Fields') : tr('Preview Document'),
            onPressed: () {
              _generateDocument();
              setState(() => _previewMode = !_previewMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppColors.accent),
            tooltip: tr('Copy Draft'),
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      body: WatermarkBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Selector Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTe ? 'టెంప్లేట్ ఎంచుకోండి' : tr('SELECT DOCUMENT TEMPLATE'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _templateChip(
                          DocumentTemplateType.policeComplaint,
                          isTe ? 'పోలీస్ ఫిర్యాదు / FIR' : 'Police Complaint',
                          Icons.local_police_rounded,
                          const Color(0xFFF43F5E),
                        ),
                        _templateChip(
                          DocumentTemplateType.rtiApplication,
                          isTe ? 'RTI దరఖాస్తు (సమాచార హక్కు)' : 'RTI Application',
                          Icons.description_rounded,
                          const Color(0xFF10B981),
                        ),
                        _templateChip(
                          DocumentTemplateType.consumerNotice,
                          isTe ? 'వినియోగదారు నోటీసు' : 'Consumer Notice',
                          Icons.shopping_cart_rounded,
                          const Color(0xFFF59E0B),
                        ),
                        _templateChip(
                          DocumentTemplateType.unpaidDuesNotice,
                          isTe ? 'చెల్లింపు బకాయిల నోటీసు' : 'Unpaid Dues Notice',
                          Icons.mail_rounded,
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Auto-fill & Action bar
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _fillSampleData,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: Text(isTe ? 'నమూనా డేటా నింపండి' : tr('Fill Sample Data')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<String?>(
                    valueListenable: TtsService.instance.currentlyPlayingId,
                    builder: (context, playingId, _) {
                      final isPlaying = playingId == 'doc_generator_preview';
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                          color: isPlaying ? Colors.red : AppColors.accent,
                        ),
                        tooltip: tr(isPlaying ? 'Stop Reading' : 'Listen Aloud'),
                        onPressed: _toggleTts,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.email_outlined, color: AppColors.accent),
                    tooltip: tr('Share via Email'),
                    onPressed: _shareViaEmail,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_previewMode) ...[
                // Preview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    _generatedText,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    isTe ? 'పూర్తి నోటీసు కాపీ చేయండి' : tr('Copy Generated Document to Clipboard'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                // Input Form
                _buildField('Your Full Name (Complainant / Applicant)', _senderNameController),
                _buildField('Your Address with City & Pincode', _senderAddressController),
                _buildField('Your Mobile / Contact Number', _senderPhoneController),
                _buildField('Recipient Authority / Person Title', _recipientNameController),
                _buildField('Organization / Department / Police Station', _recipientOrgController),
                _buildField('Recipient Office Address', _recipientAddressController),
                _buildField('Date / Period of Incident / Purchase', _incidentDateController),
                _buildField('Location of Incident / Jurisdiction', _incidentLocationController),
                _buildField('Subject Line', _subjectController),
                _buildField('Detailed Facts & Incident Description', _detailsController, maxLines: 4),
                _buildField('Relief, Demands & Statutory Deadline', _demandController, maxLines: 3),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _generateDocument();
                    setState(() => _previewMode = true);
                  },
                  icon: const Icon(Icons.description_rounded),
                  label: Text(
                    isTe ? 'పత్రాన్ని సిద్ధం చేయండి (Preview & Export)' : tr('Generate Document Preview'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateChip(DocumentTemplateType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: isSelected ? color : AppColors.border),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            _previewMode = false;
          });
          _fillSampleData();
        }
      },
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              onChanged: (_) => _generateDocument(),
              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
