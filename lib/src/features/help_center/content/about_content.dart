/// Plain reference content for "حول Smart Publisher" — see
/// `user_guide_content.dart`'s docblock for why this stays outside the ARB
/// files. Verified against the actual backend/Flutter code on 2026-08-10;
/// nothing here describes a feature that isn't real.
class AboutContent {
  const AboutContent._();

  static const String systemDefinition =
      'Smart Publisher منصة لإدارة وربط الحسابات الاجتماعية، وإنشاء '
      'المحتوى وجدولته ونشره ومتابعته من مكان واحد — مع دعم كامل '
      'للمؤسسات المتعددة، وأعضائها، وأدوارهم، ونظام موافقة إداري قبل '
      'النشر.';

  static const List<String> goals = <String>[
    'توحيد إدارة المنصات الاجتماعية المتعددة في مكان واحد.',
    'تقليل تكرار العمل بين إنشاء المحتوى ونشره على كل منصة.',
    'تنظيم صلاحيات أعضاء المؤسسة بدقة حسب الدور.',
    'تسهيل إنشاء وجدولة ونشر المحتوى.',
    'توفير موافقة إدارية قبل نشر محتوى المحررين.',
    'متابعة الحسابات والصفحات وتحليلات الأداء.',
    'حماية بيانات كل مؤسسة وعزلها تمامًا عن المؤسسات الأخرى.',
  ];

  /// Only features with real, verified code behind them — never a
  /// screen/endpoint that exists but returns mock data.
  static const List<String> realFeatures = <String>[
    'تعدد المؤسسات وتبديل المؤسسة النشطة',
    'إدارة أعضاء المؤسسة وأدوارهم',
    'ربط الحسابات الاجتماعية الحقيقية (Facebook وTelegram)',
    'إدارة صفحات وقنوات النشر',
    'إنشاء المسودات',
    'النشر المباشر',
    'الجدولة',
    'طلبات الموافقة على المنشورات',
    'مكتبة الوسائط',
    'التقويم',
    'التحليلات',
    'الإشعارات',
    'سجل تدقيق العمليات',
    'الوضع الفاتح والداكن',
  ];

  static const List<String> security = <String>[
    'عزل بيانات كل مؤسسة عن بيانات المؤسسات الأخرى بالكامل.',
    'عدم عرض رموز الوصول أو أسرار المنصات لأي مستخدم في أي واجهة.',
    'تشفير بيانات اتصال الحسابات الاجتماعية أثناء التخزين.',
    'التحقق من صلاحية كل عملية على الخادم، وليس فقط إخفاء الزر في الواجهة.',
    'تسجيل العمليات المهمة في سجل تدقيق قابل للمراجعة.',
    'إمكانية فصل أو حذف أي حساب اجتماعي مرتبط في أي وقت.',
    'عدم مشاركة بيانات الدخول الخاصة بك مع أي عضو آخر في المؤسسة.',
  ];

  static const String copyrightHolder = 'Smart Publisher';
}
