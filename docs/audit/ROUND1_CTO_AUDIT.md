# تقرير مراجعة تقنية شاملة — Smart Publisher
## الجولة الأولى: البنية المعمارية (Flutter + Laravel)، الأمن، التكامل

**تاريخ الإصدار:** 2026-07-24
**نطاق هذه الجولة:** البنية المعمارية لتطبيق Flutter والباك إند Laravel، الأمن، التكامل بين الطرفين (3 من أصل 9 محاور مطلوبة كاملة).
**منهجية المراجعة:** فحص فعلي لكل ملف (قراءة مباشرة، Grep شامل، Glob/find، فحص commits) عبر 22 عملية تدقيق مستقلة، منها 17 محور تدقيق أولي + 5 عمليات تحقق عكسي (adversarial verification) مخصصة لإعادة فحص الملاحظات التي تعطلت تقنيًا في الجولة الأولى بسبب انقطاع الجلسة. **لا يوجد أي رقم أو نسبة في هذا التقرير غير مبني على دليل فعلي من الكود.**

---

## القسم الأول: الملخص التنفيذي

المشروع في حالة **"سقالة معمارية موثقة توثيقًا جيدًا، لكن غير موصولة عمليًا بالتنفيذ الحقيقي"** على كلا الطرفين. هذا هو الاكتشاف الأهم في هذه الجولة:

1. **فجوة معمارية جوهرية في الباك إند (Laravel):** مجلدات `app/Domain/*`، `app/Application/{Handlers,UseCases}`، و`app/Infrastructure/{Repositories,Persistence}` **فارغة تمامًا (صفر ملف PHP)** رغم رسائل commits تدّعي صراحة "implement CQRS structure" و"add architecture docs, validators, policies, and mappers". كل منطق الأعمال الفعلي (٪45+ استدعاء Eloquent مباشر موثّق بالسطر) يعيش داخل طبقة الـ Controllers مباشرة. نفس النمط بالضبط يتكرر في تطبيق Flutter: طبقة `application/` بأكملها (mediators, pipelines, transactions) ملفات **فارغة 0 بايت**، وuse cases مسجّلة في DI لكنها ميتة فعليًا لأن الشاشات تتجاوزها.

2. **أخطر ثغرة أمنية مؤكدة:** في `UserController::update` (Laravel)، أي مستخدم يملك صلاحية `users.update` فقط (وليس `roles.assign`) يستطيع تمرير حقل `roles` وتعيين نفسه أو أي مستخدم آخر **admin** — تصعيد صلاحيات كامل (Privilege Escalation). إضافة لذلك: نظام الصلاحيات الشامل `'*'` الذي يصدره الخادم لا يتوافق مع منطق المطابقة الحرفية في Flutter (`ScopeAuthorizer`)، مما يعني أن **التطبيق يمنع نفسه محليًا من تنفيذ أي عملية كتابة (نشر، رفع وسائط، تحليلات) بعد كل تسجيل دخول ناجح** — وهذا ليس افتراضًا بل تم تتبعه سطرًا بسطر وتأكيده مرتين بشكل مستقل.

3. **أخطر مشكلة تكامل:** قائمة المنشورات (أهم ميزة في التطبيق) **تعود فارغة دائمًا وبصمت** عند الاتصال بالباك إند الحقيقي، لأن Flutter يبحث عن مفتاح `items` بينما Laravel يرسل `data`/`meta`. نفس النمط يتكرر حرفيًا في لوحة التحليلات (تبحث عن حقول لا وجود لها، وحتى المسار المستهدف `/analytics/dashboard` غير موجود في الباك إند — فشل 404 كامل)، وفي تسجيل الخروج (لا يستدعي أي endpoint خلفي إطلاقًا، فتبقى التوكنات صالحة على الخادم إلى الأبد).

**الخلاصة المباشرة:** الأساسات التقنية (Riverpod DI بلا اعتماديات دائرية، تخزين توكنات آمن، معالجة أخطاء مركزية بلا تسريب stack traces، منع SQL Injection) **سليمة وجيدة**. لكن **الطبقات المعمارية "المتقدمة" الموثقة في رسائل commits والتوثيق الداخلي غير منفّذة عمليًا**، و**نقاط التكامل الحرجة بين Flutter وLaravel معطّلة فعليًا وليست نظريًا** — هذا مشروع في مرحلة تطوير نشطة، **بعيد عن أي جاهزية للإطلاق التجريبي** حتى تُصلَح فجوات P0 الموثقة أدناه.

---

## القسم الثاني: درجات المحاور

| المحور | الدرجة | ملاحظة سريعة |
|---|---|---|
| **البنية المعمارية — Flutter (متوسط 7 محاور)** | **38%** | سقالة CQRS/Mediator/Pipeline فارغة بالكامل؛ شاشات تتجاوز use cases |
| — حدود الطبقات وSOLID | 42% | application/ سقالة غير موصولة؛ features/authentication مهجور بالكامل |
| — Dependency Injection (Riverpod) | 62% | لا تعارض مكتبات، لكن 31 استخدام ref.read مقابل 0 ref.watch |
| — Repository Pattern | 42% | ScheduleRepository وLaravelPublishRepository كود ميت؛ SyncWorker لا يُستدعى أبدًا |
| — CQRS / Use Cases | 8% | لا وجود فعلي لـ Commands/Queries/Handlers؛ Mediator/Pipeline/Transaction 0 بايت |
| — DTOs / Mappers / Contracts | 38% | ازدواجية Mapper كاملة؛ casts غير آمنة في 3 عقود؛ عقدا calendar وsettings ميتان |
| — Event Bus | 48% | خطأ حرج: فشل handler بسيط يُسقط عملية إنشاء منشور ناجحة |
| — Validators / Policies | 25% | مكتوبة بجودة لكن غير مستدعاة إطلاقًا؛ تعارض نموذج أدوار |
| **البنية المعمارية — Laravel (متوسط 5 محاور)** | **29%** | DDD/CQRS/Repository غير منفّذين إطلاقًا؛ منطق الأعمال كله في Controllers |
| — DDD / Domain / Application | 15% | 0 ملف PHP في Domain وHandlers وUseCases |
| — Repository Pattern / Service Layer | 12% | 0 ملف في Repositories/Persistence؛ 45+ استدعاء Eloquent مباشر في Controllers |
| — طبقة HTTP (Controllers/Requests/Resources) | 42% | مسارات AccountController مفقودة كليًا؛ تسرّب بيانات محتمل في posts.index |
| — DI والتفويض (Policies) | 32% | ثغرة تصعيد صلاحيات حرجة؛ 2/7 Models فقط لديها Policy |
| — Jobs/Queue | 42% | idempotency جيد جزئيًا؛ لا backoff فعلي؛ Events/Listeners/Notifications غائبة كليًا |
| **الأمن (متوسط محورين)** | **52%** | لا SQL Injection، لكن تصعيد صلاحيات حرج + تخزين توكن ضعيف نسبيًا |
| — أمن Laravel | 46% | تصعيد صلاحيات عبر UserController::update؛ رفع ملفات بلا تحقق نوع |
| — أمن Flutter | 58% | تخزين آمن حقيقي (لا SharedPreferences)، لكن تشفير XOR ضعيف ولا Certificate Pinning |
| **التكامل Flutter↔Laravel (متوسط 3 محاور)** | **29%** | معظم نقاط التكامل الحرجة معطّلة فعليًا وليس نظريًا |
| — عقود API (Resources/Contracts/Envelope) | 27% | إشعارات/حسابات/تحليلات بها أعطال 404 أو فشل صامت |
| — تدفق المصادقة | 32% | logout لا يستدعي الخادم؛ scope `'*'` يكسر كل عمليات الكتابة |
| — الرفع والأنماط المشتركة | 27% | قائمة المنشورات فارغة دائمًا؛ حد حجم فيديو 500MB مقابل 50MB في الخادم |
| **المتوسط العام لهذه الجولة (17 محورًا)** | **35%** | |

> **ملاحظة منهجية:** هذه الدرجات تعكس *جودة التنفيذ الفعلي مقابل الوعد المعماري*، وليس عدد الأخطاء الوظيفية البسيطة. مشروع بدرجة منخفضة هنا قد يكون قريبًا من العمل بشكل صحيح إذا رُبطت الطبقات الموجودة فعليًا (وهي مكتوبة بجودة معقولة) بمسار التنفيذ الحقيقي — المشكلة الغالبة هي "غير موصول" وليس "غير موجود إطلاقًا".

---

## القسم الثالث: قائمة الأخطاء المؤكدة (بعد التحقق العكسي)

كل بند أدناه **CONFIRMED** فعليًا (قراءة مباشرة للملف + توثيق سطر) أو صدر من عملية تحقق عكسي مستقلة ثانية. الترتيب من الأخطر للأقل خطورة. مستوى الخطورة المذكور هو **المصحَّح** بعد التحقق (قد يختلف عن التصنيف الأولي).

### 🔴 حرجة (Critical) — تتطلب إصلاحًا قبل أي إطلاق تجريبي

**BUG-001 | SEC-LARAVEL-01**
**المكان:** `app/Http/Controllers/Api/V1/UserController.php` (دالة `update`)
**الوصف:** أي مستخدم يملك صلاحية `users.update` فقط يستطيع تمرير حقل `roles` ضمن طلب التحديث وتعيين نفسه أو مستخدمًا آخر بدور `admin`، متجاوزًا صلاحية `roles.assign` المخصصة لهذا الغرض تمامًا.
**السبب:** غياب فحص صريح يمنع تعديل حقل `roles` إلا لحامل صلاحية `roles.assign` تحديدًا.
**التأثير:** تصعيد صلاحيات كامل (Privilege Escalation) — أي حساب "مدير محتوى" عادي يمكنه أن يجعل نفسه Super Admin.
**الحل:** فصل تحديث `roles` عن `update` العام في Controller/Policy منفصلة تتحقق من `roles.assign` صراحة، وتجاهل حقل `roles` تمامًا في مسار `update` القياسي.
**الأولوية:** P0

**BUG-002 | INT-AUTH-01**
**المكان:** `lib/src/core/security/scope_authorizer.dart:4-12` (Flutter) + `app/Http/Controllers/Api/V1/AuthController.php:183` (Laravel، `$scope = ['*']`)
**الوصف:** الخادم يصدر دائمًا صلاحية شاملة `'*'`، بينما `ScopeAuthorizer.hasScopes` في Flutter يقارن مطابقة حرفية (`requiredScopes.every(grantedScopes.contains)`) بلا أي معالجة لرمز `'*'`. أي طلب يتطلب صلاحية محددة (`posts.write`, `publish.write`, `media.write`...) يُرفض **محليًا** بخطأ 403 مصطنع قبل الوصول للشبكة إطلاقًا.
**السبب:** غياب دعم wildcard في منطق مطابقة الصلاحيات على العميل.
**التأثير:** **كسر فعلي لمعظم وظائف التطبيق الأساسية** (نشر، رفع وسائط، قراءة تحليلات، كتابة منشورات) لأي مستخدم بعد تسجيل الدخول بنجاح — تم التحقق منه مرتين بشكل مستقل.
**الحل:** تعديل `ScopeAuthorizer.hasScopes` ليتعامل مع `'*'` كصلاحية شاملة (early return true)، أو إصدار scopes حقيقية متمايزة من الخادم.
**الأولوية:** P0

**BUG-003 | INT-UPLOAD-01**
**المكان:** `lib/src/features/posts/data/post_repository_impl.dart:206-220` + `app/Http/Controllers/Api/V1/PostController.php`
**الوصف:** قائمة المنشورات تعود **فارغة دائمًا وبصمت** عند الاتصال بالباك إند الفعلي، لأن الكود يبحث فقط عن `List` مباشرة أو مفتاح `items`، بينما الاستجابة الفعلية هي `{'data':[...], 'meta':{...}}`.
**السبب:** عدم مزامنة عقد الاستجابة بين الطرفين (الكود كُتب بافتراض شكل استجابة مختلف).
**التأثير:** شاشة قائمة المنشورات **لن تعرض أي منشور أبدًا** رغم نجاح الطلب HTTP 200 — فشل صامت تام لأهم ميزة في التطبيق.
**الحل:** تعديل `_listViaNetwork` ليقرأ `payload['data']` كمصدر أساسي، وتوحيد شكل الاستجابة (data أو items) عبر كل الـ Controllers.
**الأولوية:** P0

**BUG-004 | INT-UPLOAD-02**
**المكان:** `app/Http/Resources/AnalyticsResource.php:15-27` + `lib/src/features/analytics/data/analytics_repository_impl.dart:103-118`
**الوصف:** لوحة التحليلات تقرأ حقولاً (`top_posts`, `total_reach`, `total_engagement`, `total_impressions`, `average_engagement_rate`) غير موجودة إطلاقًا في استجابة الباك إند. **والأخطر:** المسار الذي يستدعيه Flutter (`/v1/analytics/dashboard`) **غير موجود إطلاقًا** في `routes/api.php` (المسار الوحيد المسجّل هو `/analytics`) — أي فشل 404 كامل، وليس فقط قيمًا صفرية.
**السبب:** عدم مزامنة العقد + عدم وجود المسار المستهدف في الباك إند.
**التأثير:** لوحة التحليلات معطّلة بالكامل (404) لأي مستخدم.
**الحل:** إما إضافة مسار `/analytics/dashboard` فعلي في Laravel يطابق الحقول المتوقعة، أو تعديل Flutter لاستدعاء `/analytics` الموجود فعليًا مع تحويل الحقول.
**الأولوية:** P0

**BUG-005 | INT-AUTH-02**
**المكان:** `lib/src/features/auth/application/auth_session_controller.dart:122-134` + `app/Http/Controllers/Api/V1/AuthController.php:158-179`
**الوصف:** تسجيل الخروج في Flutter **لا يستدعي أي endpoint خلفي إطلاقًا** (تنظيف محلي فقط)، رغم أن Laravel يوفر `/auth/logout` فعليًا. وحتى لو أُصلح ذلك، فإن `logout()` في الخادم يحذف access token فقط ولا يمسّ refresh token المقترن (يبقى صالحًا حتى 30 يومًا).
**السبب:** غياب استدعاء API عند logout من جهة العميل + غياب منطق حذف جماعي للتوكنات المرتبطة بنفس الجهاز من جهة الخادم.
**التأثير:** "تسجيل الخروج" **لا ينهي الجلسة فعليًا من جهة الخادم بتاتًا** في أي سيناريو واقعي — خطر أمني حقيقي على الأجهزة المشتركة/المسروقة.
**الحل:** إضافة `LaravelEndpoints.authLogout` واستدعاؤه من `logout()`، وتعديل الخادم ليحذف كل التوكنات المرتبطة بنفس `device_name` عند logout.
**الأولوية:** P0

**BUG-006 | ARCH-FLUTTER-01**
**المكان:** `lib/src/offline/sync/sync_worker.dart:20`
**الوصف:** `SyncWorker.runOnce` هي الآلية الوحيدة التي تُفرغ outbox (العمليات المؤجلة أثناء انقطاع الشبكة)، لكنها **لا تُستدعى من أي مكان في التطبيق بأكمله** رغم أن `syncWorkerProvider` مسجّل في DI.
**السبب:** لم يُربط SyncWorker بأي محفّز فعلي (عودة الاتصال، مؤقّت دوري، بدء التطبيق).
**التأثير:** أي منشور أو وسائط تُنشأ/تُعدَّل أثناء انقطاع الشبكة **تبقى عالقة في الطابور للأبد** ولا تُزامَن أبدًا مع الخادم، رغم أن الواجهة تُظهر رسائل توحي بأن المزامنة ستحدث — ميزة "العمل دون اتصال" معطّلة فعليًا بالكامل.
**السبب:** عدم ربط `runOnce` بأي مستمع اتصال أو مهمة دورية.
**الحل:** ربط `SyncWorker.runOnce` بمستمع اتصال شبكة فعلي (`connectivity_plus`) + مهمة دورية + استدعاء عند إقلاع التطبيق.
**الأولوية:** P0

**BUG-007 | ARCH-LARAVEL-01**
**المكان:** `app/Domain/*`, `app/Application/{Handlers,UseCases}`, `app/Infrastructure/{Repositories,Persistence}`
**الوصف:** كل هذه المجلدات فارغة تمامًا (صفر ملف PHP)، رغم رسائل commits (`9285ec8`, `a311390`, `b2d677d`) تدّعي صراحة تنفيذ بنية CQRS/DDD وRepository Pattern. **100%** من منطق الأعمال المفحوص (5+ Controllers) يعيش مباشرة فوق Eloquent.
**السبب:** سقالة معمارية أُنشئت (docs + مجلدات) دون تنفيذ فعلي.
**التأثير:** صعوبة اختبار حقيقية (لا اختبارات وحدة فعلية سوى `ExampleTest.php` الافتراضي)، اقتران كامل بين طبقة HTTP وقاعدة البيانات، ودَين تقني كبير يصعّب أي تغيير مستقبلي في قاعدة البيانات أو منطق الأعمال.
**الحل:** إما البدء الفعلي بتنفيذ طبقة Repository حقيقية لأهم الكيانات (Post, MediaAttachment على الأقل) في هذه الجولة، أو تحديث التوثيق/رسائل commits ليعكس الواقع وتأجيل القرار المعماري لخطة واضحة (Sprint مخصص).
**الأولوية:** P0 (كقرار معماري) / P1 (كتنفيذ تدريجي)

**BUG-008 | SEC-LARAVEL-02**
**المكان:** `app/Http/Controllers/Api/V1/MediaLibraryController.php` (دالة `store`)
**الوصف:** رفع الملفات لا يتحقق من نوع/امتداد الملف الفعلي (لا `mimes`/`mimetypes` في قاعدة التحقق) — فقط حد حجم (`max:51200`).
**السبب:** قاعدة تحقق ناقصة في Form validation.
**التأثير:** إمكانية رفع ملفات تنفيذية أو ضارة (php, exe, ...) متنكرة بامتداد بريء.
**الحل:** إضافة `mimes:jpg,png,mp4,mov,...` صريحة + فحص Magic Bytes الفعلي للملف قبل التخزين.
**الأولوية:** P0

### 🟠 عالية (High)

**BUG-009 | ARCH-LARAVEL-02** — `app/Http/Controllers/Api/V1/PostController.php::index`: القائمة لا تُقيَّد بالمستخدم رغم أن صلاحية `posts.view` ممنوحة لأدوار غير إدارية (manager, editor) — تسرّب بيانات محتمل بين المستخدمين. **P1**

**BUG-010 | ARCH-LARAVEL-03** — `app/Providers/AppServiceProvider.php`: تسجيل الصلاحيات (Policies) يغطي 2 فقط من أصل 7 Models (Post, MediaAttachment)؛ `BranchController`, `UserController`, `SocialAccountController`, `PublishingController` بلا أي تفويض على مستوى الكائن (فقط middleware عام). **P1**

**BUG-011 | ARCH-LARAVEL-04** — `UserController::createToken`: أي حامل صلاحية `tokens.revoke` يمكنه إصدار توكن كامل الصلاحيات لأي مستخدم آخر (انتحال هوية محتمل). **P1**

**BUG-012 | ARCH-LARAVEL-05** — `app/Http/Controllers/Api/V1/AccountController.php`: يحتوي فقط دالة `index()`، بينما `routes/api.php` يسجّل `connect`/`show`/`update`/`destroy` غير الموجودة إطلاقًا — أي استدعاء من Flutter لربط/فصل حساب اجتماعي يفشل بخطأ 500 دائمًا. **P0** (وُثّق ضمن التكامل، لكنه في جوهره خطأ تنفيذ Laravel ناقص)

**BUG-013 | INT-AUTH-03** — `lib/src/core/network/network_interceptor.dart:267-288`: فشل تجديد التوكن النهائي لا يُطلق تسجيل خروج تلقائي؛ المستخدم يبقى "ظاهريًا مسجّل دخول" مع تعطل كل الطلبات دون أي توجيه. **P1**

**BUG-014 | INT-UPLOAD-03** — حد حجم الفيديو: 500MB في Flutter (`media_validation.dart:7`) مقابل 50MB فقط في Laravel (`MediaLibraryController.php:49`، `max:51200` لكل أنواع الملفات) — أي فيديو بين 50-500MB يُرفض حتمًا من الخادم بعد اجتياز التحقق المحلي. **P1**

**BUG-015 | INT-UPLOAD-04** — `ResumableUploadManager` لا يوفر استئنافًا فعليًا: الجلسات في الذاكرة فقط، `updateProgress` لا تُستدعى أبدًا، لا `Content-Range`/chunking فعلي رغم الاسم المضلل "Resumable". **P1**

**BUG-016 | INT-UPLOAD-05** — انزياح توقيت حقيقي عند الجدولة: `PostRequestDtoV1` يرسل وقتًا محليًا بدون تحويل UTC (`toUtc()` غائبة)، بينما الخادم يعمل بتوقيت UTC — تم التحقق من أن `_scheduledAt` يُبنى فعليًا كوقت محلي من منتقي التاريخ، أي الخلل **واقعي وليس نظريًا** (فرق 3 ساعات لمستخدم في بغداد مثلًا). **P1**

**BUG-017 | INT-UPLOAD-06** — `CalendarController` و`AnalyticsController` لا يدعمان أي pagination/sort/filter/search إطلاقًا — استعلام ثابت دائمًا لأحدث 50 سجل. **P2**

**BUG-018 | INT-API-01** — قائمة الإشعارات (`notification_repository_impl.dart:24`) تُقرأ دائمًا فارغة بصمت لأن `NotificationController` يرسل `{'unread','items'}` (Map) بينما العميل يتوقع List مباشرة. **P1**

**BUG-019 | INT-API-02** — `markAsRead`/`markAllAsRead` يستدعيان مسارات (`PATCH /notifications/{id}`, `POST /notifications/mark-all-read`) **غير موجودة إطلاقًا** في الباك إند (فقط `GET /notifications` مسجّل). **P1**

**BUG-020 | INT-API-03** — `LaravelEndpoints.publishJobs` (`/publish/jobs`) **مستخدم فعليًا** في `laravel_publish_repository.dart` لكن **غير موجود إطلاقًا** في `routes/api.php` (العمليات الفعلية بمسارات مختلفة تمامًا: `/posts/{post}/publish-now`, `/publishing/tick`...). **P1**

**BUG-021 | INT-API-04** — حقلا `attachments`/`platforms` في `posts_contract_v1.dart` لا يصلان أبدًا من الباك إند (الحقول الفعلية: `media_attachments`, `branch`) — فقدان بيانات صامت لأي واجهة تعرضهما. **P1**

**BUG-022 | ARCH-FLUTTER-02** — `lib/src/core/di/app_providers.dart`: 8 من أصل 13 use case (المبنية على `BaseUseCase`) مسجّلة في DI لكنها غير مستدعاة من أي واجهة إطلاقًا (كامل feature analytics + compress/delete/generate/sync). **P2**

**BUG-023 | ARCH-FLUTTER-03** — `create_post_screen.dart:243`: شاشة النشر تتجاوز `PublishPost` use case وPublishPolicy المسجَّلين وتستدعي `PublishEngine` مباشرة — تحقق العنوان/المنصة المتصلة غير مُفعّل فعليًا في مسار النشر الحقيقي. **P1**

**BUG-024 | ARCH-FLUTTER-04** — طبقة `application/mappers` مكررة بالكامل مع `BackendContractMapperV1` (المستخدم فعليًا)؛ `PostMapper` تحديدًا يُسقط `attachments`/`platforms` ويثبّت `hasMedia=false` دومًا — خطر انحدار حقيقي لو استُبدل الاستدعاء بهذا المسار الميت. **P1**

**BUG-025 | ARCH-FLUTTER-05** — Casts غير آمنة (`as String`, `as bool`) في 3 عقود (`accounts_contract_v1.dart`, `media_contract_v1.dart`, `publish_contract_v1.dart`) قد تُسبب `TypeError` وقت التشغيل عند اختلاف نوع الحقل القادم من الخادم. **P1**

**BUG-026 | ARCH-FLUTTER-06** — `event_bus.dart::dispatch`: لا يعزل استثناءات الـ handlers؛ فشل handler بسيط (حتى Logging) يُسقط عملية إنشاء/تحديث منشور **ناجحة فعليًا** ويحوّلها إلى Failure ظاهر للمستخدم. **P1**

### 🟡 متوسطة (Medium) — دَين تقني/جودة، بلا تأثير مباشر على المستخدم حاليًا

هذه الملاحظات (54 بندًا إجمالاً عبر كل المحاور) **لم تخضع للتحقق العكسي الفردي** (بحكم التصميم — رُكِّز التحقق على الحرج/العالي)، لكنها موثقة بأدلة من قراءة الكود المباشرة. أبرزها:

- `ScheduleRepository` وLaravelPublishRepository: عقود/تنفيذات كاملة **كود ميت 100%** غير مسجّلة في DI.
- `DraftStorage.getDraft`/`listDrafts`: تُكتب ولا تُقرأ أبدًا.
- `domain/services/*` (PublishService, AnalyticsService...): طبقة facade معزولة تمامًا عن DI.
- `features/authentication/` (12 مجلدًا فرعيًا فارغًا بالكامل) مقابل `features/auth/` الفعلي المستخدم — تكرار/كود ميت واضح يستحق الحذف.
- عدم اتساق معالجة فشل الشبكة/offline بين 6 مستودعات (فقط 2 منها تدعم outbox فعليًا).
- `contract_version.dart`: نظام إصدار عقود شكلي بقيمة واحدة (`v1`)، يطوي أي إصدار مستقبلي غير معروف إلى `v1` بصمت.
- `mapper_registry.dart`/`mapper_factory.dart`: بنية عامة غير مُفعّلة إطلاقًا (0% تغطية فعلية).
- `calendar_contract_v1.dart` وsettings_contract_v1.dart: عقود كاملة **غير مستخدمة عبر الشبكة إطلاقًا** رغم Backend جاهز بالكامل لخدمتها.
- `PublishPostJob` (Laravel): يستخدم حالة `published` على مستوى المنشور ككل بدل كل زوج منشور/حساب — قد يُسقط النشر على حسابات أخرى بصمت.
- لا `backoff()` فعلي في أي من الـ 3 Jobs رغم إعداد `max_retries`.
- `app/Events`, `Listeners`, `Notifications`, `Mail`, `Console/Commands` **غير موجودة إطلاقًا** في الباك إند (تفصيل كامل في الجولة القادمة).
- تشفير إضافي (`DefaultEncryptionService`) في Flutter هو XOR بدائي بمفتاح ضعيف من الطابع الزمني؛ لا Certificate Pinning إطلاقًا؛ عنوان API الافتراضي `http://` وليس `https://`.

**القائمة الكاملة (54 بندًا بالتفصيل: الملف، السبب، التأثير، الحل، الأولوية) متوفرة في ملحق البيانات الخام** `docs/audit/round1_raw_data/` (سيُنشأ عند الطلب إن أردت نسخة تفصيلية كاملة لكل بند).

---

## القسم الرابع: المهام المطلوبة حسب الفريق

### Backend Team (Laravel)
- Task-001: إصلاح BUG-001 (تصعيد صلاحيات UserController) — **عاجل جدًا**
- Task-002: تنفيذ دوال AccountController الناقصة (connect/show/update/destroy) — BUG-012
- Task-003: إصلاح مسار/حقول Analytics Dashboard — BUG-004
- Task-004: إضافة تحقق نوع/امتداد الملف في MediaLibraryController — BUG-008
- Task-005: تقييد PostController::index بالمستخدم/الفرع — BUG-009
- Task-006: توسيع تسجيل Policies لبقية الـ Models (5 من 7 بلا Policy) — BUG-010
- Task-007: مراجعة UserController::createToken ضد انتحال الهوية — BUG-011
- Task-008: إضافة مسارات notifications المفقودة (mark-read/mark-all-read) — BUG-019
- Task-009: حذف access + refresh token معًا عند logout — BUG-005
- Task-010: توحيد شكل استجابة القوائم (data/meta) عبر كل الـ Controllers — BUG-003
- Task-011: قرار معماري + خطة تنفيذ تدريجي لطبقة Repository/Domain الحقيقية — BUG-007
- Task-012: إصلاح PublishPostJob لعزل حالة كل حساب اجتماعي عن الآخر
- Task-013: إضافة backoff فعلي + معالجة فشل لكل الـ Jobs الثلاثة

### Flutter Team
- Task-021: ربط SyncWorker.runOnce بمحفّز فعلي (اتصال/مؤقت/إقلاع) — BUG-006 **عاجل جدًا**
- Task-022: تعديل ScopeAuthorizer لدعم wildcard `'*'` — BUG-002 **عاجل جدًا**
- Task-023: إصلاح قراءة قائمة المنشورات (`data`/`meta`) — BUG-003
- Task-024: إصلاح تحويل الحقول في analytics_repository_impl — BUG-004
- Task-025: استدعاء `/auth/logout` فعليًا عند logout — BUG-005
- Task-026: توحيد حد حجم الفيديو مع الخادم (50MB) أو رفعه على الخادم — BUG-014
- Task-027: تحويل `scheduledAt` إلى UTC قبل الإرسال — BUG-016
- Task-028: تنفيذ استئناف رفع حقيقي أو إزالة الاسم المضلل "Resumable" — BUG-015
- Task-029: إضافة تسجيل خروج تلقائي عند فشل تجديد التوكن النهائي — BUG-013
- Task-030: عزل استثناءات event handlers عن transaction الكتابة الأساسية — BUG-026
- Task-031: حذف application/mappers المكررة، أو دمجها كغلاف وحيد لـ BackendContractMapperV1 — BUG-024
- Task-032: توحيد casts الآمنة عبر كل عقود v1 — BUG-025
- Task-033: توحيد مسار النشر (use case واحد بدل PublishEngine المباشر) — BUG-023
- Task-034: حذف features/authentication الفارغ، وScheduleRepository/LaravelPublishRepository الميتين (أو استكمالهما)
- Task-035: قرار معماري لطبقة application/ الفارغة (حذف أو تنفيذ فعلي) — بالتوازي مع Task-011

### DevOps / Security
- Task-041: مراجعة سياسة كلمات المرور وSanctum tokens (مدة صلاحية refresh 30 يومًا + صلاحيات '*')
- Task-042: تفعيل Certificate Pinning في عميل Dio
- Task-043: التبديل الإجباري إلى HTTPS كعنوان افتراضي (لا http://)
- Task-044: استبدال DefaultEncryptionService (XOR) بتشفير حقيقي أو الاعتماد الكامل على flutter_secure_storage فقط

### QA
- Task-081: كتابة اختبارات وحدة حقيقية لـ AuthController/UserController (تغطية صفرية حاليًا خارج ExampleTest الافتراضي)
- Task-082: اختبار end-to-end لتدفق: تسجيل دخول → نشر منشور → عرضه في القائمة (يفشل حاليًا بسبب BUG-003)
- Task-083: اختبار رفع فيديو بحجم 100-400MB (يفشل حاليًا بسبب BUG-014)
- Task-084: اختبار تسجيل الخروج ثم محاولة استخدام التوكن القديم (يجب أن يفشل، حاليًا لا يفشل بسبب BUG-005)

---

## القسم الخامس: خطة العمل المقترحة (لهذه الجولة فقط)

### Sprint 1 (إصلاحات P0 الحرجة — يجب إنجازها قبل أي اختبار داخلي موسّع)
- إصلاح تصعيد الصلاحيات (BUG-001)
- إصلاح ScopeAuthorizer wildcard (BUG-002) — **بدون هذا لا يعمل أي شيء في التطبيق تقريبًا**
- إصلاح قراءة قائمة المنشورات (BUG-003)
- إصلاح/تفعيل مسار Analytics Dashboard (BUG-004)
- إصلاح logout الكامل (access + refresh) (BUG-005)
- ربط SyncWorker.runOnce (BUG-006)
- تنفيذ دوال AccountController الناقصة (BUG-012)
- إضافة تحقق نوع الملف في رفع الوسائط (BUG-008)

### Sprint 2 (إصلاحات P1 عالية الأثر)
- توحيد حدود حجم الملفات، تحويل UTC للجدولة، إصلاح مسارات الإشعارات وpublish/jobs
- عزل event handlers عن transaction الكتابة
- توحيد مسار النشر (use case واحد)، حذف/توحيد الـ mappers المكررة
- توسيع تغطية Policies في Laravel، معالجة فشل Jobs

### قرار معماري مطلوب (لا يُنفَّذ ضمن Sprint واحد، لكن يجب اتخاذ القرار في هذه المرحلة)
- هل نستكمل تنفيذ DDD/CQRS/Repository الحقيقي في Laravel وapplication/ في Flutter، أم نحذف السقالة الفارغة ونوثّق المعمارية الفعلية (Controllers + Eloquent مباشرة في الباك إند، use cases بسيطة عبر Riverpod في Flutter)؟ **هذا القرار يحدد شكل الجولات القادمة من هذا التدقيق.**

---

## القسم السادس: التقييم النهائي لهذه الجولة

**الحالة الحالية: جاهز للتطوير النشط فقط — غير جاهز حتى لتجربة داخلية موسّعة.**

المبرر: 8 أخطاء حرجة (P0) مؤكدة تمس وظائف أساسية جدًا (تسجيل الدخول لا يفتح أي عملية كتابة عمليًا بسبب BUG-002، قائمة المنشورات فارغة دائمًا بسبب BUG-003، التحليلات معطّلة بسبب BUG-004، تسجيل الخروج غير فعّال أمنيًا بسبب BUG-005، والعمل دون اتصال معطّل كليًا بسبب BUG-006). هذه ليست "أخطاء صقل" بل **تكسر التدفق الأساسي للمنتج** (نشر محتوى ← عرضه ← تحليله)، وهو جوهر عرض القيمة (value proposition) للمنتج بأكمله.

**لن يكون المشروع جاهزًا حتى لبيتا داخلية** قبل إغلاق كل بنود Sprint 1 أعلاه والتحقق منها فعليًا (اختبار يدوي كامل لتدفق: تسجيل دخول → نشر → عرض في القائمة → تحليلات → تسجيل خروج).

### ما هو مؤجَّل للجولة القادمة (Round 2) وأولويته
1. **قاعدة البيانات بعمق** (فهارس، علاقات، Migration quality) — أولوية عالية، خصوصًا بعد اكتشاف Anemic Model في Laravel.
2. **بقية ملفات Laravel** بالتفصيل: Events/Listeners/Notifications/Mail/Broadcasting/Console Commands (**غائبة كليًا حاليًا** — يحتاج فحصًا مستقلاً لتحديد ما هو مطلوب فعليًا للمنتج).
3. **بقية Flutter**: UI/State Management التفصيلي، الأداء، تسرّبات الذاكرة، Localization، Theme، Responsive UI، تحميل الصور، الإشعارات (Push).
4. **جودة الكود التفصيلية**: Code Smells، Duplicate/Dead Code (بدأنا برصده هنا لكنه يحتاج مسحًا شاملاً)، Magic Numbers.
5. **الاختبارات**: التغطية الحالية شبه معدومة (Unit Tests) — يحتاج قسمًا مستقلاً كاملاً بما فيه تحديد نسبة التغطية المستهدفة.
6. **التوثيق، CI/CD، المراقبة (Monitoring)، النسخ الاحتياطي، خطة الإطلاق** — لم تُفحص بعد إطلاقًا في أي جولة.

---

*ملاحظة على منهجية إعداد هذا التقرير: تم تشغيل 17 عملية تدقيق مستقلة (فحص فعلي بأدوات Read/Grep/Glob لكل ملف)، ثم إخضاع كل الملاحظات الحرجة/العالية (70 ملاحظة) لتحقق عكسي (adversarial verification) مستقل يُعيد فتح الملفات الحقيقية للتأكد أو الرفض. من أصل 70: 43 مؤكدة بالكامل، 27 مرفوضة فعليًا (استُبعدت من هذا التقرير). محاولة أولى تعطلت جزئيًا بسبب انقطاع تقني في منتصف التنفيذ (نفاد حصة استخدام الجلسة)؛ أُعيد تنفيذ كل جزء تأثر بذلك بشكل مستقل ومن الصفر قبل اعتماد أي رقم في هذا التقرير.*
