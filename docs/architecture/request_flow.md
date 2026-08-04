# Request Execution Flow

يوضح هذا المستند التدفق الفعلي المطبَّق حاليًا في الكود (وليس تصميمًا نظريًا). النسخة السابقة من هذا المستند وصفت طبقة Mediator/Validation Pipeline/Policy Engine/RequestHandler لم تُنفَّذ فعليًا قط (ملفات 0 بايت غير مستوردة من أي مكان)، وتم حذفها في جولة تدقيق 2026-07-24 (BUG-007) لتفادي تضليل أي قارئ مستقبلي. التدفق الحقيقي أبسط:

[UI Trigger] (`ref.read(xRepositoryProvider)` من شاشة Riverpod)
      ↓
[Repository Implementation] (مثال: `PostRepositoryImpl`)
      ├─ إن وُجد `NetworkClient`: طلب شبكة فعلي عبر `BackendContractMapperV1`
      │      ├─ نجاح → تحويل الاستجابة إلى Entity وإرجاعها
      │      └─ `NetworkFailure` → حفظ محليًا (`DraftStorage`) + إدراج في `OutboxStore`
      └─ بلا `NetworkClient`: تخزين في الذاكرة محليًا مباشرة
      ↓
[BackendContractMapperV1] -> تحويل الـ Entity إلى DTO مطابق لعقد الباك إند (`backend_contracts/v1`)
      ↓
[NetworkClient / Dio] -> إرسال الطلب الفعلي إلى Laravel API

**العمل دون اتصال (Offline):** العمليات المؤجَّلة في `OutboxStore` تُفرَّغ عبر `SyncWorker.runOnce`، الذي يُستدعى دوريًا من `syncSchedulerProvider` (كل 45 ثانية + مرة عند إقلاع التطبيق) — راجع `lib/src/offline/sync/outbox_sync_handlers.dart` للاطلاع على المعالجات الفعلية لكل نوع عملية.

**ملاحظة:** لا يوجد حاليًا Mediator أو Validation Pipeline أو Policy Engine مركزي مطبَّق فعليًا. منطق التحقق (مثل صلاحيات النشر) يعيش حاليًا داخل الشاشات نفسها أو داخل الـ Repository. طبقات `application/policies` و`application/validators` و`application/mappers` مكتوبة لكنها غير موصولة بهذا التدفق حاليًا (انظر تقرير التدقيق `docs/audit/ROUND1_CTO_AUDIT.md`، BUG-023 وBUG-024) — قرار ربطها أو حذفها مؤجَّل لسبرنت لاحق.