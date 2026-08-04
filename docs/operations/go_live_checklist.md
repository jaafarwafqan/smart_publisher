# Go-Live Checklist

Smart Publisher currently has an Android closed-beta distribution workflow.
Use the complete, evidence-based checklist in
[closed_beta_release_checklist.md](closed_beta_release_checklist.md).

Do not mark a release as live until the CI gates, signed artifact,
Firebase-distribution evidence, MySQL/InnoDB reliability test, real provider
staging checks, Meta requirements, legal URLs, and support contact are all
complete.  Web deployment, canary controls, and automated rollback are not
implemented release actions in this repository and must not be represented as
such.
