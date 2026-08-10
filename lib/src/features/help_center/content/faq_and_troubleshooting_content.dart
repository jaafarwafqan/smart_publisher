import '../domain/models/help_content_models.dart';

/// The global "الأسئلة الشائعة" list shown at the end of the guide.
List<HelpFaq> buildGlobalFaqs() => const <HelpFaq>[
  HelpFaq(
    question: 'لماذا لا يظهر زر إضافة حساب؟',
    answer:
        'زر ربط الحسابات يظهر فقط لمن يملك صلاحية social_accounts.connect '
        '(Manager فأعلى). Editor وViewer يريان الحسابات لكن بدون هذا الزر.',
  ),
  HelpFaq(
    question: 'من يستطيع ربط حساب Facebook أو Telegram؟',
    answer: 'Manager وAdmin وOwner فقط — نفس صلاحية social_accounts.connect.',
  ),
  HelpFaq(
    question: 'لماذا لا يستطيع Editor النشر مباشرة؟',
    answer:
        'دور Editor لا يملك صلاحية posts.publish، بل posts.request_approval '
        'فقط — تصميم متعمَّد يفرض مراجعة قبل نشر أي محتوى ينشئه المحررون.',
  ),
  HelpFaq(
    question: 'كيف أغير المؤسسة؟',
    answer: 'من شاشة «المؤسسات» — اختر أي مؤسسة أخرى أنت عضو فعّال فيها.',
  ),
  HelpFaq(
    question: 'هل يمكن ربط الحساب نفسه بأكثر من مؤسسة؟',
    answer:
        'كل حساب اجتماعي مرتبط تابع لمؤسسة واحدة فقط داخل النظام — بيانات '
        'كل مؤسسة معزولة تمامًا عن غيرها.',
  ),
  HelpFaq(
    question: 'لماذا لا تظهر صفحة Facebook التي أديرها؟',
    answer:
        'اضغط «مزامنة الصفحات» بعد الربط لجلب قائمة محدَّثة من Facebook. '
        'إن لم تظهر بعد المزامنة، تأكد أنك مسؤول (Admin) عن تلك الصفحة '
        'على Facebook نفسه.',
  ),
  HelpFaq(
    question: 'كيف أعيد ربط حساب منتهي الصلاحية؟',
    answer:
        'كرر خطوات الربط من جديد (نفس زر «ربط» على بطاقة الحساب) — لا '
        'حاجة لحذف الحساب القديم أولًا.',
  ),
  HelpFaq(
    question: 'كيف أعرف سبب فشل المنشور؟',
    answer:
        'افتح المنشور من قائمة المنشورات أو التقويم لعرض تفاصيل كل هدف وسبب فشله إن وُجد.',
  ),
  HelpFaq(
    question: 'هل يمكن تعديل منشور تمت جدولته؟',
    answer:
        'نعم، ما دام لم يبدأ تنفيذ النشر بعد — يمكن تعديل محتواه أو موعده أو إلغاء جدولته بالكامل.',
  ),
  HelpFaq(
    question: 'من يستطيع إضافة الأعضاء؟',
    answer: 'Admin وOwner فقط، عبر صلاحية members.invite.',
  ),
  HelpFaq(
    question: 'كيف أحذف بياناتي؟',
    answer:
        'من «الإعدادات → حذف حسابي» — يسجَّل طلب دائم يراجعه مشغّل النظام قبل الحذف الفعلي، وليس حذفًا فوريًا.',
  ),
  HelpFaq(
    question: 'كيف أتواصل مع الدعم؟',
    answer:
        'راجع صفحة «حول النظام» لبيانات الدعم المتاحة في نسخة النظام الحالية.',
  ),
];

/// "استكشاف الأخطاء" — plain Arabic messages only, never a stack trace or
/// internal detail. HTTP codes reflect what the backend's own error
/// envelope actually returns to the client.
List<HelpTroubleshootingItem>
buildTroubleshootingItems() => const <HelpTroubleshootingItem>[
  HelpTroubleshootingItem(
    symptom: 'ليس لديك صلاحية لتنفيذ هذه العملية',
    fix:
        'دورك الحالي في هذه المؤسسة لا يملك الصلاحية المطلوبة. راجع قسم «الأدوار والصلاحيات» أو اطلب من مسؤول المؤسسة ترقية دورك.',
  ),
  HelpTroubleshootingItem(
    symptom: 'لم يتم اختيار مؤسسة',
    fix:
        'افتح شاشة «المؤسسات» واختر مؤسسة نشطة قبل المتابعة — لا يمكن تنفيذ أي عملية دون مؤسسة نشطة.',
  ),
  HelpTroubleshootingItem(
    symptom: 'الحساب غير متصل',
    fix: 'أعد ربط الحساب من بطاقته في لوحة المعلومات.',
  ),
  HelpTroubleshootingItem(
    symptom: 'الرمز منتهي الصلاحية / بانتظار إعادة ربط',
    fix: 'كرر خطوات الربط للحصول على رمز اتصال جديد — نفس زر «ربط».',
  ),
  HelpTroubleshootingItem(
    symptom: 'الصفحة لا تظهر عند اختيار أهداف النشر',
    fix:
        'اضغط «مزامنة الصفحات» على بطاقة الحساب، وتأكد أنك مسؤول عن تلك الصفحة على المنصة نفسها.',
  ),
  HelpTroubleshootingItem(
    symptom: 'Bot Telegram لا يستطيع النشر',
    fix:
        'تأكد أن البوت أُضيف كمشرف (Admin) في القناة مع تفعيل صلاحية نشر الرسائل، ثم أعد اختبار الاتصال.',
  ),
  HelpTroubleshootingItem(
    symptom: 'القناة غير موجودة (Telegram)',
    fix:
        'تحقق من صحة معرّف القناة (@username) أو Chat ID، وتأكد أن البوت لم يُزَل من القناة.',
  ),
  HelpTroubleshootingItem(
    symptom: 'فشل رفع الملف',
    fix:
        'تحقق من نوع الملف وحجمه: صور حتى 20 ميغابايت، فيديو حتى 500 ميغابايت، مستندات حتى 50 ميغابايت — وإلا يُرفَض الرفع.',
  ),
  HelpTroubleshootingItem(
    symptom: 'تعذر النشر على منصة واحدة ضمن منشور متعدد الأهداف',
    fix:
        'راجع تفاصيل ذلك الهدف تحديدًا داخل المنشور — بقية الأهداف تنشر بشكل مستقل ولا تتأثر بفشله.',
  ),
  HelpTroubleshootingItem(
    symptom: 'المنشور ما زال بانتظار الموافقة',
    fix:
        'يحتاج من يملك صلاحية posts.approve (Manager فأعلى) في مؤسستك لمراجعته والموافقة عليه أو رفضه.',
  ),
  HelpTroubleshootingItem(
    symptom: 'لا توجد بيانات تحليلية',
    fix:
        'يظهر هذا عندما لا يوفر مزوّد المنصة بيانات كافية بعد — ليس عطلًا؛ حاول لاحقًا بعد مرور وقت كافٍ على النشر.',
  ),
  HelpTroubleshootingItem(
    symptom: 'خطأ 401 — غير مصرّح',
    fix: 'انتهت جلستك. سجّل الدخول من جديد.',
  ),
  HelpTroubleshootingItem(
    symptom: 'خطأ 403 — ممنوع',
    fix:
        'دورك لا يملك صلاحية هذا الإجراء تحديدًا، أو تحاول تنفيذه على مؤسسة لست عضوًا فيها.',
  ),
  HelpTroubleshootingItem(
    symptom: 'خطأ 404 — غير موجود',
    fix: 'العنصر المطلوب غير موجود أو حُذف بالفعل — حدّث الشاشة وحاول مجددًا.',
  ),
  HelpTroubleshootingItem(
    symptom: 'خطأ 422 — بيانات غير صالحة',
    fix:
        'أحد الحقول المُدخَلة غير صحيح؛ راجع رسالة الخطأ المصاحبة تحت الحقل المعني.',
  ),
  HelpTroubleshootingItem(
    symptom: 'خطأ 429 — طلبات كثيرة جدًا',
    fix:
        'تجاوزت الحد المسموح من الطلبات خلال فترة قصيرة. انتظر قليلًا ثم أعد المحاولة.',
  ),
  HelpTroubleshootingItem(
    symptom: 'خطأ مؤقت من خدمة خارجية (Facebook/Telegram)',
    fix:
        'المنصة نفسها تواجه عطلًا مؤقتًا لديها. يعيد النظام محاولة الإرسال تلقائيًا للأخطاء القابلة للإصلاح؛ إن استمر الخطأ راجع حالة الخدمة لدى المزوّد.',
  ),
];

/// The role → capability table for "الأدوار والصلاحيات" — mirrors
/// `App\Enums\OrganizationRole::permissions()` exactly (verified against
/// the backend source on 2026-08-10), presented as human-readable actions
/// instead of raw permission strings.
List<RolePermissionRow> buildRolePermissionRows() => const <RolePermissionRow>[
  RolePermissionRow(
    action: 'مشاهدة كل المنشورات',
    grantedTo: <String>['viewer', 'editor', 'manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'إنشاء منشور وتعديل منشوراته الخاصة',
    grantedTo: <String>['editor', 'manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'إرسال منشور لطلب الموافقة',
    grantedTo: <String>['editor'],
  ),
  RolePermissionRow(
    action: 'الموافقة على المنشورات أو رفضها',
    grantedTo: <String>['manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'النشر المباشر دون موافقة',
    grantedTo: <String>['manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'مشاهدة الحسابات الاجتماعية والصفحات',
    grantedTo: <String>['viewer', 'editor', 'manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'ربط/فصل/حذف الحسابات الاجتماعية',
    grantedTo: <String>['manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'اختبار الاتصال ومزامنة الصفحات',
    grantedTo: <String>['manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'مشاهدة أعضاء المؤسسة',
    grantedTo: <String>['viewer', 'editor', 'manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'إضافة أعضاء أو تغيير أدوارهم أو إزالتهم',
    grantedTo: <String>['admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'مشاهدة التحليلات ومشاهدة بيانات المؤسسة',
    grantedTo: <String>['viewer', 'editor', 'manager', 'admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'تعديل اسم المؤسسة وإعداداتها',
    grantedTo: <String>['admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'مشاهدة سجل التدقيق',
    grantedTo: <String>['admin', 'owner'],
  ),
  RolePermissionRow(
    action: 'نقل ملكية المؤسسة أو حذفها',
    grantedTo: <String>['owner'],
  ),
];
