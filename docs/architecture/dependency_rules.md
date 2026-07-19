# Dependency & Coupling Rules

## The Clean Architecture Dependency Rule
* يجب أن تتوجه الاعتماديات دائماً **إلى الداخل**. الطبقات الخارجية تعتمد على الداخلية، والعكس ممنوع منعاً باتاً.
* لا يجوز لطبقة الـ `Domain` أو الـ `Application` استيراد (`import`) أي ملف من طبقة الـ `Infrastructure` أو الـ `Presentation`.

## Communication via Contracts
* أي تواصل مع قاعدة بيانات أو مستودع خارجي يتم عبر واجهة مجردة (Interface/Contract) معرفة في الطبقات الداخلية ويتم حقن تنفيذها الفعلي من الخارج باستخدام **Riverpod**.