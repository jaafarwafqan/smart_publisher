# Smart Publisher

Smart Publisher هو مشروع Flutter يهدف إلى بناء منصة متقدمة لنشر المحتوى عبر منصات التواصل الاجتماعي من خلال سير عمل منظم، وليس مجرد CRUD عادي.

التركيز الأساسي للمشروع هو:
- إنشاء منشورات
- تحسينها بالذكاء الاصطناعي
- إرفاق الوسائط
- ضغط الوسائط
- اختيار المنصات
- جدولة النشر
- تنفيذ عمليات النشر عبر Queue و Engine
- تتبع التحليلات والإشعارات

## الفكرة المعمارية

المشروع مبني حول مفهوم Workflow وليست مجرد CRUD. ولذلك تم تنظيمه على شكل طبقات واضحة:

1. Core Layer
   - Result handling عبر AppResult و Success / Failure
   - Base abstractions مثل BaseEntity و BaseRepository و BaseUseCase
   - Event Bus و Domain Events

2. Feature Layer
   - Posts
   - Platforms
   - Publish
   - Auth
   - Media
   - Schedule
   - Analytics
   - Notifications
   - AI

3. Platform Abstraction Layer
   - واجهة موحدة عبر SocialPlatform
   - مصنع المنصات عبر PlatformFactory
   - أول تنفيذ تجريبي لمنصة Telegram

4. Publish Engine Layer
   - PublishEngine
   - PublishPipeline
   - PublishStep
   - Queue Manager
   - Retry Policy
   - Logger

## هيكل المشروع

```text
lib/
  src/
    core/
      base/
      result/
      events/
    domain/
      services/
    features/
      posts/
      platforms/
      publish/
      auth/
      media/
      schedule/
      analytics/
      notifications/
      ai/
    platforms/
      core/
      telegram/
    publish_engine/
      engine/
      jobs/
      queue/
      retry/
      logs/
```

## ما تم تنفيذه حتى الآن

### 1. Core Architecture
- إضافة Result pattern
- إضافة Base abstractions
- إضافة Event Bus و Domain Events

### 2. Domain Layer
- إنشاء Entities للـ Posts والـ Draft والـ Attachment والـ Media
- إضافة Entities للمنصات والنشر والحسابات والمهام
- إنشاء Repository Interfaces الأساسية
- إنشاء Use Cases الأساسية مثل CreatePost و PublishPost و SchedulePost و DeleteDraft و GenerateAiText و CompressMedia و UploadMedia و SyncAccounts

### 3. Platform Abstraction
- إنشاء واجهة موحدة للمنصات
- إنشاء PlatformFactory
- إنشاء أول تنفيذ لمنصة Telegram

### 4. Publish Engine
- إضافة PublishEngine
- إضافة PublishPipeline و PublishStep
- إضافة Queue Manager و Retry Policy و Logger

### 5. Documentation & Design
- إضافة مواصفات API داخل docs/api
- إضافة تصميم قاعدة البيانات داخل docs/database
- إضافة workflow للنشر و state machine
- إضافة error codes و sequence diagrams

## الوثائق المتوفرة

- [docs/api/authentication.md](docs/api/authentication.md)
- [docs/api/accounts.md](docs/api/accounts.md)
- [docs/api/posts.md](docs/api/posts.md)
- [docs/api/media.md](docs/api/media.md)
- [docs/api/publish.md](docs/api/publish.md)
- [docs/api/schedules.md](docs/api/schedules.md)
- [docs/api/analytics.md](docs/api/analytics.md)
- [docs/api/notifications.md](docs/api/notifications.md)
- [docs/api/ai.md](docs/api/ai.md)
- [docs/api/webhooks.md](docs/api/webhooks.md)

- [docs/database/modules.md](docs/database/modules.md)
- [docs/database/publish_state_machine.md](docs/database/publish_state_machine.md)
- [docs/database/platform_capability_model.md](docs/database/platform_capability_model.md)
- [docs/database/queue_workflow.md](docs/database/queue_workflow.md)
- [docs/database/media_pipeline.md](docs/database/media_pipeline.md)

- [docs/errors.md](docs/errors.md)
- [docs/sequence_diagrams.md](docs/sequence_diagrams.md)

## المرحلة الحالية

المشروع الآن في مرحلة البناء المعماري الأساسية، قبل الانتقال إلى:
- Repository Implementations
- Remote/Local Data Sources
- DTOs و Mappers
- Laravel Backend Integration

## التشغيل المحلي

لتشغيل المشروع:

```bash
flutter pub get
flutter run
```

## الخطوات القادمة

1. إضافة DTOs و Mappers
2. بناء Repository Implementations
3. إضافة Remote Data Sources و Local Data Sources
4. بناء أول Integration Test حقيقي للنشر
5. إضافة Event Listeners للإشعارات والتحليلات
6. إضافة Security Layer و Offline Sync Engine

## ملاحظات مهمة

- هذا المشروع لا يركز على CRUD فقط.
- الهدف الأساسي هو بناء نظام نشر وظيفي، قابل للتوسع، ومهيأ لإضافة منصات جديدة دون إعادة كتابة الهيكل الأساسي.
- الطبقات الحالية مصممة لتكون أساسًا قويًا للتطوير المستقبلي.
