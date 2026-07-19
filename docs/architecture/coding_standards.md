# Coding Standards & Guidelines

للحفاظ على كود متناسق ونظيف كفريق عمل:

## 1. Single Responsibility Principle (SRP)
* كل ملف `Validator` مسؤول عن فحص قيمة واحدة فقط.
* كل ملف `Policy` يحتوي على شروط وقواعد عمل مرتبطة بـ Context واحد.
* المappers معزولة تماماً وتعمل في اتجاهين واضحي المعالم.

## 2. Naming Conventions
* الطلبات المعدلة للبيانات تنتهي بكلمة `Command` (مثل: `CreatePostCommand`).
* طلبات القراءة تنتهي بكلمة `Query` (مثل: `GetPostByIdQuery`).
* المعالجات تنتهي بكلمة `CommandHandler` أو `QueryHandler`.

## 3. Formatting
* الالتزام الصارم بملف `analysis_options.yaml` المرفق في المشروع.
* يمنع استخدام شروط `if` المتداخلة بعمق (Deep Nesting)؛ يُستعاض عنها بالـ Guard Clauses والـ Policy Engine.