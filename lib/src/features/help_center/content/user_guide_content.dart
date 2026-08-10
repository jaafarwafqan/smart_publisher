import 'package:flutter/material.dart' show Icons;

import '../../../core/router/route_names.dart';
import '../../organizations/application/current_organization_access.dart';
import '../domain/models/help_content_models.dart';

/// The full body of "دليل استخدام Smart Publisher". Everything here was
/// cross-checked against the actual backend/Flutter code on 2026-08-10
/// (registration flow, `OrganizationRole::permissions()`,
/// `MediaLibraryController::store()`'s real size/type limits,
/// `NotificationService`'s real call sites, `SocialOAuthManager`'s
/// mock/beta/partial classification, `ClosedBetaPublishingGate`, and
/// `config/publishing.php`'s real `Post.status` set) — nothing here is
/// aspirational. Kept as plain Arabic content constants rather than ARB
/// entries: this is long-form reference material analogous to
/// `docs/legal/*.md`, not reusable interactive UI chrome (which does go
/// through `AppLocalizations` — see the help_center screens themselves).
List<HelpSection> buildUserGuideSections() => <HelpSection>[
  _gettingStarted,
  _dashboardOverview,
  _rolesAndPermissions,
  _connectFacebook,
  _connectTelegram,
  _otherPlatforms,
  _createPost,
  _publishNow,
  _editorApprovalRequest,
  _approveOrReject,
  _scheduling,
  _calendar,
  _mediaLibrary,
  _analytics,
  _notifications,
  _manageMembers,
  _organizationSettings,
  _manageConnectedAccounts,
];

final HelpSection _gettingStarted = HelpSection(
  id: 'getting-started',
  title: 'البدء باستخدام النظام',
  icon: Icons.rocket_launch_outlined,
  articles: <HelpArticle>[
    const HelpArticle(
      id: 'getting-started.register-login',
      title: 'إنشاء حساب أو تسجيل الدخول',
      summary:
          'التسجيل ينشئ حساب مستخدم فقط — لم يعد ينشئ مؤسسة تلقائيًا ولا '
          'يجعلك مالكًا لأي مؤسسة. بعد إنشاء الحساب أو تسجيل الدخول، يتحقق '
          'النظام مما إذا كنت عضوًا فعّالًا في أي مؤسسة.',
      steps: <HelpStep>[
        HelpStep(
          'افتح شاشة تسجيل الدخول أو أنشئ حسابًا جديدًا ببريدك الإلكتروني وكلمة مرور.',
        ),
        HelpStep(
          'إذا فعّل النظام توثيق البريد الإلكتروني لحسابك، تحقق من بريدك '
          'واضغط رابط التفعيل — تظهر رسالة تذكير أعلى الإعدادات حتى تفعّل.',
        ),
      ],
    ),
    const HelpArticle(
      id: 'getting-started.no-organization',
      title: 'إذا لم تنتمِ إلى أي مؤسسة بعد',
      summary:
          'حساب جديد بلا دعوة من أي مؤسسة يبقى صالحًا لتسجيل الدخول '
          'والخروج فقط؛ تظهر شاشة «المؤسسات» فارغة مع رسالة توضح أنك لم '
          'تُضف إلى مؤسسة بعد. لا يمكنك إنشاء منشورات أو ربط حسابات حتى '
          'تنضم إلى مؤسسة.',
      notes: <String>[
        'انضمامك يتم فقط عندما يضيفك مالك مؤسسة أو مسؤولها ببريدك '
            'الإلكتروني من داخل «إدارة أعضاء المؤسسة» — لا يوجد طلب انضمام '
            'ذاتي حاليًا.',
        'بريدك يجب أن يكون مسجّلًا مسبقًا في النظام حتى يستطيع المسؤول '
            'إضافتك.',
      ],
    ),
    const HelpArticle(
      id: 'getting-started.switch-organization',
      title: 'اختيار المؤسسة النشطة وتبديلها',
      summary:
          'إن كنت عضوًا في أكثر من مؤسسة، تعمل دائمًا داخل «مؤسسة نشطة» '
          'واحدة فقط — كل البيانات التي تراها (منشورات، حسابات، أعضاء) '
          'خاصة بها فقط، ولا تُعرض أبدًا بيانات مؤسسة أخرى.',
      steps: <HelpStep>[
        HelpStep('افتح شاشة «المؤسسات».'),
        HelpStep('اختر المؤسسة التي تريد العمل فيها.'),
        HelpStep('تُحدَّث كل الشاشات فورًا لتعرض بيانات المؤسسة الجديدة فقط.'),
      ],
      actionLabel: 'انتقل إلى المؤسسات',
      actionRoute: RouteNames.organizationsPath,
    ),
    const HelpArticle(
      id: 'getting-started.logout',
      title: 'تسجيل الخروج',
      summary: 'زر تسجيل الخروج متاح من الشريط العلوي في لوحة المعلومات.',
    ),
  ],
);

final HelpSection _dashboardOverview = HelpSection(
  id: 'dashboard',
  title: 'فهم لوحة المعلومات',
  icon: Icons.dashboard_outlined,
  articles: <HelpArticle>[
    const HelpArticle(
      id: 'dashboard.stats',
      title: 'بطاقات الإحصائيات',
      summary:
          'خمس بطاقات أعلى اللوحة: إجمالي المنشورات، المجدولة، المنشورة '
          'فعليًا، الفاشلة، وعدد الحسابات المتصلة من إجمالي الحسابات '
          'الست الظاهرة.',
    ),
    const HelpArticle(
      id: 'dashboard.accounts',
      title: 'الحسابات المرتبطة',
      summary:
          'شبكة تعرض ست منصات ثابتة (Facebook، Instagram، Telegram، '
          'WhatsApp، LinkedIn، X) بحالتها الحقيقية — متصلة أو غير متصلة أو '
          'بانتظار إعادة ربط — مع أزرار الربط/قطع الاتصال/الاختبار حسب '
          'صلاحيتك.',
    ),
    const HelpArticle(
      id: 'dashboard.recent-activity',
      title: 'المنشورات الأخيرة وحالة النشر',
      summary:
          'قائمة بأحدث المنشورات مرتبة بتاريخ آخر تحديث، مع شارة لونية '
          'توضح حالة كل منشور.',
    ),
    const HelpArticle(
      id: 'dashboard.refresh',
      title: 'تحديث البيانات',
      summary:
          'تُحمَّل بيانات اللوحة تلقائيًا عند فتحها؛ عند حدوث خطأ في '
          'التحميل تظهر رسالة واضحة مع زر «إعادة المحاولة» بدل شاشة فارغة '
          'مضلِّلة.',
    ),
  ],
);

final HelpSection _rolesAndPermissions = HelpSection(
  id: 'roles',
  title: 'الأدوار والصلاحيات',
  icon: Icons.badge_outlined,
  articles: <HelpArticle>[
    const HelpArticle(
      id: 'roles.overview',
      title: 'كيف تعمل الصلاحيات',
      summary:
          'الصلاحية الفعلية لكل عضو تُحسَب على الخادم (Laravel) من دوره '
          'داخل المؤسسة الحالية فقط، وتُرسَل للتطبيق مباشرة — لا يشتق '
          'التطبيق أي صلاحية بنفسه. إن لم تظهر زر أو شاشة معينة، فهذا '
          'يعني أن دورك الحالي لا يملك الصلاحية المطلوبة، وليس عطلًا.',
      notes: <String>[
        'الجدول أسفله مطابق تمامًا لما يحدده الخادم في '
            'OrganizationRole::permissions() — لا يوجد جدول صلاحيات مختلف '
            'داخل التطبيق.',
      ],
    ),
  ],
);

final HelpSection _connectFacebook = HelpSection(
  id: 'connect-facebook',
  title: 'ربط حساب Facebook',
  icon: Icons.link,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.socialAccountsConnect],
  ),
  articles: <HelpArticle>[
    HelpArticle(
      id: 'connect-facebook.flow',
      title: 'خطوات الربط',
      summary:
          'الربط عبر OAuth الحقيقي من Meta فقط — لا حاجة لإدخال أي App '
          'Secret أو Access Token يدويًا في أي وقت.',
      requiredPermission: const RequiredPermission(
        anyOf: <String>[OrganizationPermissions.socialAccountsConnect],
        roleHint: 'Manager فأعلى',
      ),
      steps: const <HelpStep>[
        HelpStep('افتح لوحة المعلومات وانتقل إلى بطاقة Facebook.'),
        HelpStep('اضغط «ربط» على بطاقة Facebook.'),
        HelpStep(
          'يفتح المتصفح صفحة تسجيل الدخول الحقيقية لـMeta — سجّل الدخول '
          'بحسابك على Facebook.',
        ),
        HelpStep(
          'وافق على الصلاحيات التي يطلبها Smart Publisher لإدارة صفحاتك.',
        ),
        HelpStep('يعيدك Meta تلقائيًا إلى Smart Publisher بعد الموافقة.'),
        HelpStep('اضغط «مزامنة الصفحات» لجلب صفحاتك الحقيقية من Facebook.'),
        HelpStep('اختر الصفحة أو الصفحات التي تريد النشر عليها.'),
        HelpStep(
          'اضغط «اختبار الاتصال» للتأكد أن الربط سليم قبل الاعتماد عليه '
          'في منشور مهم.',
        ),
        HelpStep(
          'إن انتهت صلاحية الاتصال لاحقًا (تظهر الحالة «بانتظار إعادة '
          'ربط»)، كرر خطوات الربط من جديد — لا حاجة لحذف الحساب أولًا.',
        ),
      ],
      notes: <String>[
        'منشور يحتوي وسائط (صور/فيديو) ولديه صفحة Facebook ضمن أهدافه لا '
            'يمكن نشره حاليًا — Facebook يستقبل النص فقط دون الوسائط في '
            'هذا الإصدار؛ احذف المرفقات أو استبعد هدف Facebook قبل النشر.',
      ],
    ),
  ],
);

final HelpSection _connectTelegram = HelpSection(
  id: 'connect-telegram',
  title: 'ربط Telegram',
  icon: Icons.send_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.socialAccountsConnect],
  ),
  articles: <HelpArticle>[
    const HelpArticle(
      id: 'connect-telegram.flow',
      title: 'خطوات الربط',
      summary:
          'Telegram يُربط عبر Bot Token من BotFather — لا يوجد OAuth للمتصفح هنا.',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.socialAccountsConnect],
        roleHint: 'Manager فأعلى',
      ),
      steps: <HelpStep>[
        HelpStep('من تطبيق Telegram، تحدّث مع @BotFather وأنشئ بوتًا جديدًا.'),
        HelpStep(
          'احتفظ بالـBot Token الذي يعطيك إياه BotFather في مكان آمن — لا '
          'تشاركه مع أحد ولا ترسله في أي محادثة عامة.',
        ),
        HelpStep('أضف البوت إلى القناة أو المجموعة التي تريد النشر إليها.'),
        HelpStep(
          'امنح البوت صلاحية «مشرف» (Admin) في القناة مع تفعيل «نشر '
          'الرسائل».',
        ),
        HelpStep(
          'في Smart Publisher، اضغط «ربط» على بطاقة Telegram وأدخل Bot Token.',
        ),
        HelpStep('أدخل معرّف القناة (@username) أو Chat ID الرقمي.'),
        HelpStep('اضغط «اختبار الاتصال» للتحقق أن البوت يستطيع النشر فعليًا.'),
        HelpStep(
          'يعرض النظام اسم القناة الحقيقي بعد التحقق الناجح — تأكد أنه صحيح.',
        ),
        HelpStep('احفظ الحساب.'),
      ],
      notes: <String>[
        'لا يعرض التطبيق Bot Token بعد حفظه في أي مكان — أعد إدخاله من '
            'BotFather إن احتجت لربط قناة أخرى.',
      ],
      faqs: <HelpFaq>[
        HelpFaq(
          question: 'ظهرت رسالة «رمز البوت غير صالح» — ما السبب؟',
          answer:
              'Bot Token المدخل غير صحيح أو تم إبطاله من BotFather. أنشئ '
              'رمزًا جديدًا وأعد المحاولة.',
        ),
        HelpFaq(
          question: 'ظهرت رسالة «لم يتم العثور على القناة»؟',
          answer:
              'إما المعرّف الذي أدخلته غير صحيح، أو أن البوت لم يُضَف إلى '
              'القناة بعد، أو أُزيل منها. تحقق من إضافة البوت كمشرف ثم '
              'أعد اختبار الاتصال.',
        ),
      ],
    ),
  ],
);

final HelpSection _otherPlatforms = HelpSection(
  id: 'other-platforms',
  title: 'بقية المنصات',
  icon: Icons.hourglass_empty_outlined,
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'other-platforms.whatsapp',
      title: 'WhatsApp — قريبًا',
      summary:
          'زر الربط يعرض «قريبًا» في الواجهة الحالية. البنية التحتية على '
          'الخادم جاهزة جزئيًا فقط: الاتصال واكتشاف الأرقام حقيقيان إذا '
          'تفعّلا مستقبلًا، لكن إرسال الرسائل غير منفَّذ إطلاقًا بعد — لذلك '
          'يبقى مغلقًا أمام المستخدم حتى اكتمال ميزة النشر.',
    ),
    HelpArticle(
      id: 'other-platforms.mock',
      title: 'Instagram وX وLinkedIn — قريبًا',
      summary:
          'هذه المنصات ليست موصولة بخدمة حقيقية بعد على الخادم؛ زر '
          'الربط يعرض «قريبًا» ولا تُقدَّم أي خطوات ربط وهمية. سيُعلَن عند '
          'توفرها فعليًا.',
    ),
  ],
);

final HelpSection _createPost = HelpSection(
  id: 'create-post',
  title: 'إنشاء منشور',
  icon: Icons.edit_note_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.postsCreate],
  ),
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'create-post.flow',
      title: 'خطوات إنشاء منشور',
      summary: 'إنشاء منشور جديد بمحتوى ووسائط ومنصات مستهدفة.',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.postsCreate],
      ),
      steps: <HelpStep>[
        HelpStep(
          'اضغط «أنشئ منشورًا» من لوحة المعلومات أو من قائمة المنشورات.',
        ),
        HelpStep('اكتب نص المنشور — يمكن تخصيص نص مختلف لكل منصة عند الحاجة.'),
        HelpStep(
          'أضف صورًا أو فيديو من مكتبة الوسائط أو ارفع ملفًا جديدًا — '
          'الصور حتى 20 ميغابايت (JPG وPNG وGIF وWebP)، والفيديو حتى '
          '500 ميغابايت (MP4 وMOV وWebM).',
        ),
        HelpStep('اختر المؤسسة النشطة (تُحدَّد تلقائيًا من مؤسستك الحالية).'),
        HelpStep('اختر المنصات والصفحات المستهدفة من الحسابات المتصلة فعليًا.'),
        HelpStep('عايِن المنشور كما سيظهر على كل منصة قبل الحفظ.'),
        HelpStep('احفظه كمسودة إن لم تكن جاهزًا للنشر أو الجدولة بعد.'),
      ],
      notes: <String>[
        'رفع ملف بحجم أو نوع غير مدعوم يُرفَض برسالة واضحة قبل أي محاولة '
            'نشر.',
      ],
      actionLabel: 'أنشئ منشورًا',
      actionRoute: RouteNames.postsCreatePath,
    ),
  ],
);

final HelpSection _publishNow = HelpSection(
  id: 'publish-now',
  title: 'النشر المباشر',
  icon: Icons.campaign_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.postsPublish],
  ),
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'publish-now.flow',
      title: 'تنفيذ النشر المباشر',
      summary:
          'النشر المباشر متاح فقط لمن يملك صلاحية posts.publish '
          '(Manager وAdmin وOwner). محرر المحتوى (Editor) لا يملك هذا '
          'الزر إطلاقًا — يرسل طلب موافقة بدلًا منه (راجع قسم «نشر '
          'المحرر»).',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.postsPublish],
      ),
      steps: <HelpStep>[
        HelpStep('راجع نص المنشور والوسائط والمنصات المستهدفة.'),
        HelpStep('اضغط «نشر الآن».'),
        HelpStep(
          'يبدأ النظام تنفيذ النشر لكل منصة مستهدفة بشكل مستقل — نجاح '
          'منصة لا يعتمد على نجاح الأخرى.',
        ),
      ],
      notes: <String>[
        'حالات المنشور الحقيقية: مسودة، مجدول، قيد النشر، منشور، فشل '
            'جزئي (نجحت بعض المنصات وفشلت أخرى)، فشل، أو ملغى — لا توجد '
            'حالة باسم غير هذه في النظام.',
        'عند فشل جزئي، راجع تفاصيل كل هدف لمعرفة أي منصة نجحت وأيها '
            'فشلت وسبب الفشل.',
        'إعادة المحاولة التلقائية للمحاولات القابلة للإصلاح مدمجة في '
            'نظام النشر بالخلفية؛ لا يحتاج المستخدم لأي إجراء يدوي لها.',
      ],
    ),
  ],
);

final HelpSection _editorApprovalRequest = HelpSection(
  id: 'editor-approval-request',
  title: 'نشر المحرر وطلب الموافقة',
  icon: Icons.rate_review_outlined,
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'editor-approval-request.flow',
      title: 'إرسال منشور للموافقة',
      summary:
          'محرر المحتوى (Editor) يستطيع إنشاء منشوراته الخاصة وتحديد '
          'صفحاتها، لكنه لا يستطيع نشرها مباشرة — يجب أن يوافق عليها '
          'Manager أو Admin أو Owner أولًا.',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.postsRequestApproval],
        roleHint: 'Editor',
      ),
      steps: <HelpStep>[
        HelpStep('أنشئ المنشور كالمعتاد.'),
        HelpStep('اختر الصفحات المستهدفة.'),
        HelpStep(
          'اضغط «إرسال للموافقة» بدل «نشر الآن» (الزر الوحيد المتاح لك).',
        ),
        HelpStep('ينتقل المنشور إلى قائمة «بانتظار الموافقة» عند المسؤولين.'),
        HelpStep('تابع حالة طلبك من قائمة منشوراتك.'),
        HelpStep('إذا رُفض الطلب، اقرأ سبب الرفض المكتوب من المراجع.'),
        HelpStep('عدّل المنشور حسب الملاحظة وأعد إرساله للموافقة.'),
      ],
    ),
  ],
);

final HelpSection _approveOrReject = HelpSection(
  id: 'approve-reject',
  title: 'الموافقة والرفض',
  icon: Icons.fact_check_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.postsApprove],
  ),
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'approve-reject.flow',
      title: 'مراجعة طلبات الموافقة',
      summary:
          'متاح فقط لمن يملك صلاحية posts.approve (Manager وAdmin '
          'وOwner).',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.postsApprove],
      ),
      steps: <HelpStep>[
        HelpStep('افتح «طلبات الموافقة».'),
        HelpStep('راجع نص المنشور والوسائط والصفحات المستهدفة.'),
        HelpStep('اضغط «موافقة» لتنفيذ النشر أو الجدولة كما طلبها المُرسل.'),
        HelpStep(
          'أو اضغط «رفض» واكتب سببًا واضحًا — يظهر السبب للمُرسل حتى '
          'يعدّل المنشور.',
        ),
      ],
      notes: <String>[
        'يعيد النظام التحقق من صلاحية الموافقة والنشر لحظة التنفيذ الفعلي '
            'في الخلفية، وليس فقط لحظة الضغط على الزر — إن سُحبت صلاحيتك '
            'أو تعطّلت الصفحة المستهدفة بين الموافقة والتنفيذ، يتوقف النشر '
            'بأمان بدل أن يمضي بصلاحية لم تعد قائمة.',
      ],
    ),
  ],
);

final HelpSection _scheduling = HelpSection(
  id: 'scheduling',
  title: 'جدولة المنشورات',
  icon: Icons.schedule,
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'scheduling.flow',
      title: 'جدولة منشور لوقت لاحق',
      summary: 'جدولة منشور ليُنشَر تلقائيًا في وقت محدد مستقبلًا.',
      steps: <HelpStep>[
        HelpStep('من شاشة إنشاء المنشور، اختر «جدولة» بدل «نشر الآن».'),
        HelpStep('حدد التاريخ.'),
        HelpStep(
          'حدد الوقت — يُحسَب بتوقيت جهازك ويُخزَّن داخليًا بتوقيت UTC.',
        ),
        HelpStep('احفظ الجدولة.'),
        HelpStep(
          'يمكنك تعديل الجدولة أو إلغاؤها ما دام المنشور لم يبدأ النشر بعد.',
        ),
      ],
      notes: <String>[
        'إن انتهت صلاحية اتصال الحساب المستهدف قبل موعد النشر، يتوقف '
            'النشر بأمان دون تنفيذ جزئي مضلِّل — أعد ربط الحساب قبل الموعد '
            'لتفادي ذلك.',
      ],
    ),
  ],
);

final HelpSection _calendar = HelpSection(
  id: 'calendar',
  title: 'التقويم',
  icon: Icons.calendar_month_outlined,
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'calendar.flow',
      title: 'استعراض المنشورات المجدولة',
      summary: 'التقويم يعرض حصريًا المنشورات المجدولة القادمة الحقيقية.',
      steps: <HelpStep>[
        HelpStep('افتح شاشة «التقويم».'),
        HelpStep('استعرض المنشورات المجدولة لليوم.'),
        HelpStep('اضغط على أي منشور لفتحه.'),
        HelpStep('عدّله أو ألغِ جدولته حسب صلاحيتك على هذا المنشور.'),
      ],
      actionLabel: 'افتح التقويم',
      actionRoute: RouteNames.calendarPath,
    ),
  ],
);

final HelpSection _mediaLibrary = HelpSection(
  id: 'media-library',
  title: 'مكتبة الوسائط',
  icon: Icons.perm_media_outlined,
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'media-library.flow',
      title: 'رفع وإعادة استخدام الوسائط',
      summary:
          'كل الملفات المرفوعة تُخزَّن في مكتبة واحدة قابلة لإعادة الاستخدام في أي منشور لاحق.',
      steps: <HelpStep>[
        HelpStep('افتح «مكتبة الوسائط».'),
        HelpStep(
          'ارفع ملفًا: صور JPG وPNG وGIF وWebP حتى 20 ميغابايت، فيديو '
          'MP4 وMOV وWebM حتى 500 ميغابايت، أو مستندات PDF وWord وExcel '
          'وCSV وZip حتى 50 ميغابايت.',
        ),
        HelpStep('أضف وسومًا (Tags) اختيارية لتسهيل البحث لاحقًا.'),
        HelpStep(
          'أعد استخدام أي ملف موجود عند إنشاء منشور جديد دون رفعه مجددًا.',
        ),
        HelpStep('احذف الملفات غير المستخدمة عند الحاجة.'),
      ],
      notes: <String>[
        'صلاحية حذف الوسائط أوسع لدى Manager فما فوق؛ Editor يرى المكتبة '
            'ويرفع ملفاته لكن نطاق حذفه أضيق.',
        'لا ترفع أي ملفات تحتوي بيانات حساسة أو رموز وصول — المكتبة '
            'مشتركة بين كل من يملك صلاحية العرض في مؤسستك.',
      ],
      actionLabel: 'افتح مكتبة الوسائط',
      actionRoute: RouteNames.mediaLibraryPath,
    ),
  ],
);

final HelpSection _analytics = HelpSection(
  id: 'analytics',
  title: 'التحليلات',
  icon: Icons.insights_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.analyticsView],
  ),
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'analytics.flow',
      title: 'قراءة تحليلات المنشورات',
      summary:
          'مقاييس حقيقية فقط: الوصول (Reach)، مرات الظهور '
          '(Impressions)، التفاعل (Engagement) ونسبته، وأفضل منصة وأفضل '
          'ساعة نشر إن توفّرت بيانات كافية.',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.analyticsView],
      ),
      notes: <String>[
        'عندما لا تكفي البيانات لتحديد أفضل منصة أو أفضل ساعة، يعرض '
            'النظام «لا توجد بيانات كافية بعد» صراحة بدل رقم مختلَق.',
        'كل رقم معروض جاء من مزوّد المنصة الحقيقي؛ لا تُعرَض بيانات '
            'تجريبية على أنها تحليلات فعلية.',
      ],
      actionLabel: 'افتح التحليلات',
      actionRoute: RouteNames.analyticsPath,
    ),
  ],
);

final HelpSection _notifications = HelpSection(
  id: 'notifications',
  title: 'الإشعارات',
  icon: Icons.notifications_active_outlined,
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'notifications.flow',
      title: 'أنواع الإشعارات المتاحة فعليًا',
      summary:
          'إشعارات طلب الموافقة، والموافقة، والرفض، ونجاح النشر، وفشله، '
          'والفشل الجزئي، وإلغاء النشر، واستنفاد إعادة المحاولة — كل هذه '
          'حقيقية ومفعّلة.',
      notes: <String>[
        'انتهاء صلاحية اتصال حساب أو الحاجة لإعادة ربطه لا يُرسَل حاليًا '
            'كإشعار مستقل — تظهر حالته فقط على بطاقة الحساب في لوحة '
            'المعلومات، فتحقق منها دوريًا إن كنت تعتمد على حساب مهم.',
        'اضغط على أي إشعار لتعليمه كمقروء.',
      ],
      actionLabel: 'افتح الإشعارات',
      actionRoute: RouteNames.notificationsPath,
    ),
  ],
);

final HelpSection _manageMembers = HelpSection(
  id: 'manage-members',
  title: 'إدارة أعضاء المؤسسة',
  icon: Icons.group_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.membersInvite],
  ),
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'manage-members.flow',
      title: 'إضافة وإدارة الأعضاء',
      summary:
          'متاح لـAdmin وOwner. الإضافة تتم ببريد إلكتروني لمستخدم مسجَّل '
          'مسبقًا في النظام — ليست دعوة بريد إلكتروني جديدة.',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.membersInvite],
        roleHint: 'Admin وOwner',
      ),
      steps: <HelpStep>[
        HelpStep('افتح «أعضاء الفريق».'),
        HelpStep('اضغط «إضافة عضو» وأدخل بريده الإلكتروني.'),
        HelpStep('اختر دوره — Viewer هو الافتراضي إن لم تحدد دورًا آخر.'),
        HelpStep('لتغيير دور عضو موجود، اختر الدور الجديد من قائمته المنسدلة.'),
        HelpStep('لإزالة عضو، اضغط زر الإزالة بجانب اسمه.'),
      ],
      notes: <String>[
        'لا يمكنك تغيير دورك الخاص ولا إزالة نفسك من المؤسسة.',
        'لا يمكن أبدًا ترك المؤسسة بلا مالك واحد على الأقل — محاولة تنزيل '
            'رتبة آخر Owner أو إزالته تُرفَض حتى تنقل الملكية لعضو آخر '
            'أولًا.',
        'منح دور Owner لعضو آخر (نقل الملكية) لا يستطيعه إلا Owner حالي.',
      ],
      actionLabel: 'إدارة الأعضاء',
      actionRoute: RouteNames.organizationMembersPath,
    ),
  ],
);

final HelpSection _organizationSettings = HelpSection(
  id: 'organization-settings',
  title: 'إعدادات المؤسسة',
  icon: Icons.settings_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.organizationUpdate],
  ),
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'organization-settings.flow',
      title: 'تعديل بيانات المؤسسة',
      summary: 'تعديل اسم المؤسسة متاح لمن يملك صلاحية organization.update.',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.organizationUpdate],
      ),
      notes: <String>[
        'لا يوجد نظام خطط أو اشتراكات أو فوترة في هذا الإصدار — كل الأعضاء '
            'داخل المؤسسة يعملون على نفس المساحة دون تمييز حسب «باقة».',
      ],
      actionLabel: 'افتح الإعدادات',
      actionRoute: RouteNames.settingsPath,
    ),
  ],
);

final HelpSection _manageConnectedAccounts = HelpSection(
  id: 'manage-accounts',
  title: 'إدارة الحسابات المرتبطة',
  icon: Icons.groups_2_outlined,
  requiredPermission: const RequiredPermission(
    anyOf: <String>[OrganizationPermissions.socialAccountsUpdate],
  ),
  articles: const <HelpArticle>[
    HelpArticle(
      id: 'manage-accounts.flow',
      title: 'صيانة الحسابات المتصلة',
      summary: 'متاح لـManager فما فوق.',
      requiredPermission: RequiredPermission(
        anyOf: <String>[OrganizationPermissions.socialAccountsUpdate],
        roleHint: 'Manager فأعلى',
      ),
      steps: <HelpStep>[
        HelpStep('راجع حالة الحساب على بطاقته في لوحة المعلومات.'),
        HelpStep('اضغط «اختبار الاتصال» للتحقق من صحة الربط الحالي.'),
        HelpStep('اضغط «مزامنة» لتحديث قائمة الصفحات من المنصة.'),
        HelpStep('أعد الربط عند ظهور حالة «بانتظار إعادة ربط».'),
        HelpStep('اضغط «قطع الاتصال» لفصل الحساب دون حذف بياناته المخزّنة.'),
        HelpStep('اضغط «حذف» لإزالة الحساب نهائيًا من المؤسسة.'),
      ],
      notes: <String>[
        'حذف حساب لا يحذف المنشورات القديمة التي نُشرت من خلاله سابقًا؛ '
            'لكن أي منشور مجدول لم يُنفَّذ بعد ويستهدف هذا الحساب سيفشل عند '
            'موعده لأن الحساب لم يعد متاحًا — راجع الجدولة وأزل الهدف قبل '
            'الحذف.',
      ],
    ),
  ],
);
