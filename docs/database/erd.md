# Database Design (ERD)

## Core Tables

### users
- id
- organization_id
- name
- email
- password_hash
- created_at
- updated_at

### organizations
- id
- name
- slug
- created_at

### workspaces
- id
- organization_id
- name
- created_at

### social_accounts
- id
- workspace_id
- platform
- account_name
- access_token
- refresh_token
- expires_at
- is_active

### social_pages
- id
- social_account_id
- platform_page_id
- page_name
- page_type
- is_enabled

### posts
- id
- workspace_id
- user_id
- title
- content
- status
- scheduled_at
- created_at
- updated_at

### drafts
- id
- post_id
- content
- version
- updated_at

### attachments
- id
- post_id
- name
- path
- mime_type
- size_bytes
- created_at

### media
- id
- post_id
- url
- mime_type
- size_bytes
- is_compressed
- created_at

### publish_jobs
- id
- post_id
- status
- retry_count
- progress
- error_message
- created_at
- updated_at

### publish_logs
- id
- publish_job_id
- platform
- status
- message
- created_at

### scheduled_posts
- id
- post_id
- publish_at
- timezone
- is_active

### notifications
- id
- user_id
- title
- body
- is_read
- created_at

### ai_requests
- id
- post_id
- prompt
- response
- created_at

### ai_templates
- id
- workspace_id
- name
- prompt
- created_at

### analytics
- id
- post_id
- platform
- impressions
- clicks
- shares
- reactions
- updated_at

### platform_tokens
- id
- social_account_id
- platform
- token
- expires_at

### refresh_tokens
- id
- user_id
- token
- expires_at

### devices
- id
- user_id
- device_name
- device_id
- last_seen_at

### activity_logs
- id
- user_id
- action
- metadata
- created_at
```
