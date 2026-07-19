# Application Architecture Layers

النظام مقسم إلى طبقات معزولة لحماية الكود وتسهيل عملية الفحص (Testing):

## 1. Domain Layer (اللب الأساسي)
* تحتوي على الـ Entities و الـ Value Objects والـ Exceptions الخاصة بالنطاق.
* مستقلة تماماً ولا تعتمد على أي مكتبات خارجية أو أي طبقة أخرى.

## 2. Application Layer (منطق الأعمال)
* تحتوي على الـ Commands, Queries, Handlers, Validators, والـ Policies.
* تعتمد فقط على طبقة الـ Domain.

## 3. Infrastructure Layer (التقنيات الخارجية)
* تحتوي على الـ Repositories الفعلية، الربط مع الـ APIs الخارجية (Facebook SDK, Dio)، وطبقة التخزين (Storage).

## 4. Presentation Layer (واجهة المستخدم)
* صفحات ومكونات الـ Flutter والـ State Management (Riverpod).