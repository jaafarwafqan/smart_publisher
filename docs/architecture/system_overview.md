# System Overview - Smart Publisher

## Purpose
منصة متقدمة ومستقلة لإدارة ونشر المحتوى عبر منصات التواصل الاجتماعي المتعددة (X, Facebook, Telegram) باستخدام بنية تحتية هندسية مرنة تضمن الأمان والتوسع والتحقق الصارم من سياسات النشر قبل التنفيذ.

## Architectural Patterns (الحالة الفعلية بعد تدقيق 2026-07-24)
* **Repository Pattern:** كل feature يملك عقد Repository مجرّد (abstract class) وتنفيذًا فعليًا (`*RepositoryImpl`) يتعامل مع الشبكة والتخزين المحلي عبر `BaseRepository`.
* **Riverpod DI:** حقن الاعتماديات عبر `core/di/app_providers.dart`، تُقرأ الشاشات منه مباشرة (`ref.read`) دون طبقة use case موحّدة إلزامية.
* **Offline Outbox:** عمليات الشبكة الفاشلة تُحفظ في `OutboxStore` وتُعاد عبر `SyncWorker` المُشغَّل دوريًا من `syncSchedulerProvider`.
* **Backend Contracts (v1):** طبقة DTOs صريحة (`backend_contracts/v1`) لكل مورد، تُحوَّل عبر `BackendContractMapperV1` إلى/من كيانات الدومين.

> **CQRS، Mediator Pattern، وPolicy Engine المذكورة سابقًا هنا لم تُنفَّذ فعليًا قط** (سقالة فارغة 0 بايت تم حذفها في BUG-007 من تقرير `docs/audit/ROUND1_CTO_AUDIT.md`). إن قررت الشركة تبنّي هذه الأنماط لاحقًا، يجب تنفيذها فعليًا قبل توثيقها هنا مجددًا.