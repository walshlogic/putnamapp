import 'package:intl/intl.dart';

class OriRecord {
  OriRecord({
    required this.id,
    required this.bookNumber,
    required this.pageNumber,
    this.fileDate,
    this.fromParty,
    this.toParty,
    required this.instrumentNumber,
    this.transactionCode,
    this.description,
  });

  final int id;
  final int bookNumber;
  final int pageNumber;
  final DateTime? fileDate;
  final String? fromParty;
  final String? toParty;
  final String instrumentNumber;
  final String? transactionCode;
  final String? description;

  String get fileDateString =>
      fileDate == null ? '' : DateFormat('MM/dd/yyyy').format(fileDate!);

  String get bookPageDisplay => 'Bk $bookNumber · Pg $pageNumber';

  String get transactionDisplay =>
      transactionCodeLabels[transactionCode] ?? transactionCode ?? '';

  factory OriRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return OriRecord(
      id: json['id'] as int,
      bookNumber: json['book_number'] as int,
      pageNumber: json['page_number'] as int,
      fileDate: parseDate(json['file_date']),
      fromParty: json['from_party'] as String?,
      toParty: json['to_party'] as String?,
      instrumentNumber: json['instrument_number'] as String,
      transactionCode: json['transaction_code'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Quick-filter categories: each maps to a set of transaction codes.
enum OriQuickCategory { all, deeds, mortgages, liens, court, vitals }

const Map<OriQuickCategory, List<String>> oriQuickCategoryCodes =
    <OriQuickCategory, List<String>>{
  OriQuickCategory.all: <String>[],
  OriQuickCategory.deeds: <String>['D', 'DTX', 'EAS', 'PL', 'PLR'],
  OriQuickCategory.mortgages: <String>['MTG', 'SAT', 'ASG', 'MOD', 'REL'],
  OriQuickCategory.liens: <String>['LN', 'LN2', 'LP', 'NCL', 'JUD'],
  OriQuickCategory.court: <String>['ORD', 'CP', 'CCJ', 'PRO', 'AFF', 'BND'],
  OriQuickCategory.vitals: <String>['MAR', 'DC', 'MIL', 'POA'],
};

const Map<OriQuickCategory, String> oriQuickCategoryLabels =
    <OriQuickCategory, String>{
  OriQuickCategory.all: 'All',
  OriQuickCategory.deeds: 'Deeds',
  OriQuickCategory.mortgages: 'Mortgages',
  OriQuickCategory.liens: 'Liens',
  OriQuickCategory.court: 'Court',
  OriQuickCategory.vitals: 'Vitals',
};

/// Human-readable label for each transaction code (from orihelp.txt).
const Map<String, String> transactionCodeLabels = <String, String>{
  'LN': 'Lien',
  'LP': 'Lis Pendens',
  'MAR': 'Marriage Record',
  'MIL': 'Military Discharge',
  'MOD': 'Modification',
  'MTG': 'Mortgage',
  'NOT': 'Notice',
  'NOC': 'Notice of Commencement',
  'NCL': 'Notice of Contest of Lien',
  'ORD': 'Order',
  'PR': 'Partial Release',
  'PL': 'Plat',
  'PLR': 'Plat Related',
  'POA': 'Power of Attorney',
  'PRO': 'Probate',
  'REL': 'Release',
  'RES': 'Restrictions',
  'SAT': 'Satisfaction',
  'TER': 'Termination',
  'TRA': 'Transfer',
  'UNK': 'Unknown',
  'INT': 'Intangible Tax',
  'CPY': 'Copies',
  'MSC': 'Misc Fees',
  'DDS': 'Deed Doc Stamp',
  'PAS': 'Passports',
  'MFS': 'Microfilm',
  'BIL': 'Billed Recordings',
  'AFF': 'Affidavit',
  'AGR': 'Agreement',
  'AGD': 'Agreement/Contract',
  'ASG': 'Assignment',
  'BND': 'Bond',
  'CTF': 'Certificate',
  'CCJ': 'Certified Court Judgment',
  'CND': 'Condominium Declaration',
  'CP': 'Court Paper',
  'DC': 'Death Certificate',
  'D': 'Deed',
  'EAS': 'Easement',
  'FIN': 'UCC Financing Statement',
  'GOV': 'Government-Related',
  'JUD': 'Judgment',
  'LN2': 'Unknown Transaction',
  'DTX': 'Tax Deed',
  'TD1': 'Tax Deed Fee (Pre-Sale)',
  'TDP': 'Tax Deed Deposit',
  'FM1': 'Finance Misc 1',
  'FM2': 'Finance Misc 2',
  'NSF': 'NSF Check Payment',
  'COC': 'Certificate of Compliance',
  'HRS': 'HRS Recording Fees',
  'TR1': 'Transfer of Lien to Security',
  'ADS': 'Agreement Doc Stamp',
  'FCS': 'Finance Contracted Services',
  'FJW': 'Finance Jury/Witness',
  'CBD': 'Clerk to Board Fees',
  'POS': 'Rec Postage',
  'PLM': 'Multi-Page Plat',
  'TDU': 'Tax Deed (No Recording)',
};
