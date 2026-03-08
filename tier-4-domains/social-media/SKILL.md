---
name: social-media
tier: 4
category: domain
version: 1.0.0
description: Social media management — auto-posting, engagement monitoring, content scheduling, analytics.
triggers:
  - "social media"
  - "facebook post"
  - "instagram"
  - "TikTok"
  - "auto post"
  - "engagement"
  - "social content"
requires:
  - builder
  - n8n-mcp
recommends:
  - content-gen
  - messaging
related:
  - "[[content-gen]]"
  - "[[facebook-ads]]"
---

# 📣 Social Media Management

Organic social media automation: scheduling, posting, monitoring, and analytics.

## Architecture: Content Lifecycle

```
Planning:
├── Content calendar (Google Sheets)
├── Asset library (Google Drive)
└── Approval workflow
    ↓
Publishing:
├── Auto-post to Facebook Pages
├── Auto-post to Instagram Business
├── Auto-post to TikTok
├── Cross-post with platform-specific formatting
    ↓
Monitoring:
├── Comment tracking & auto-reply
├── Mention/DM monitoring
├── Sentiment analysis (AI)
    ↓
Analytics:
├── Engagement metrics collection
├── Performance reports (weekly/monthly)
└── Best-time-to-post analysis
```

## Key Patterns

### 1. Content Calendar Execution

```
Schedule Trigger (every 30min)
→ Read calendar from Sheets (columns: date, time, platform, content, media_url, status)
→ Filter: WHERE date=today AND time <= now AND status="SCHEDULED"
→ For each post:
  → Download media from Drive
  → Post to specified platform
  → Update status to "PUBLISHED"
  → Store post_id for tracking
```

### 2. Cross-Platform Posting

```javascript
function formatForPlatform(platform, content) {
  switch (platform) {
    case "facebook":
      return { message: content.text, link: content.url };
    case "instagram":
      return {
        caption: content.text + "\n.\n.\n.\n" + content.hashtags.join(" "),
        image_url: content.media,
      };
    case "tiktok":
      return {
        title: content.text.substring(0, 150),
        video_url: content.media,
      };
  }
}
```

### 3. Facebook Page Posting

```
POST /{page_id}/feed
Body: { message, link, access_token }

Photo post:
POST /{page_id}/photos
Body: { url: image_url, caption, access_token }

Video post:
POST /{page_id}/videos
Body: { file_url, description, access_token }
```

### 4. Comment Monitoring & Auto-Reply

```
Schedule Trigger (every 15min)
→ GET /{post_id}/comments?since={last_check}
→ For each new comment:
  → IF contains question keywords → AI generate reply → POST /{comment_id}/comments
  → IF contains negative sentiment → flag + notify team via [[messaging]]
  → IF contains purchase intent → route to [[crm-sales]]
→ Update last_check timestamp
```

### 5. Engagement Analytics Collection

```
Daily Schedule
→ For each active post (last 30 days):
  → GET /{post_id}?fields=likes.summary(true),comments.summary(true),shares
  → Calculate engagement rate: (likes + comments + shares) / reach * 100
→ Append to Analytics Sheet
→ Weekly: generate performance summary report
```

### 6. Best Time to Post Analysis

```javascript
// Aggregate engagement by hour of day
const engagementByHour = {};
for (const post of posts) {
  const hour = new Date(post.created_time).getHours();
  if (!engagementByHour[hour]) engagementByHour[hour] = { total: 0, count: 0 };
  engagementByHour[hour].total += post.engagement_rate;
  engagementByHour[hour].count++;
}
// Sort by avg engagement → recommend top 3 posting times
```

### 7. UGC (User-Generated Content) Collection

```
Monitor tagged posts/mentions
→ Filter quality (engagement threshold)
→ Request permission (auto-DM)
→ If approved → save to asset library
→ Log in UGC tracker sheet
```

## Credentials Required

- `facebookGraphApi` — Page access token with pages_manage_posts
- Instagram Business API (via Facebook Graph API)
- TikTok Content Publishing API
- `googleSheetsOAuth2Api` — calendar + analytics
- `googleDriveApi` — asset library
