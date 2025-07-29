
# Product Requirements Document (PRD)
**Education Q&A App**

---

## 1. Overview
An interactive mobile app that lets students and parents capture or upload images of textbooks, screens, or homework sheets. Users can crop question areas (spanning up to 3 images per single question) and submit them to a multimodal language model, which returns answers and detailed explanations.

---

## 2. Objectives
- **Ease of use:** Simple capture, crop, and submit workflow  
- **High accuracy:** Leverage state‑of‑the‑art multimodal LM for precise answers  
- **Learning support:** Provide step‑by‑step explanations  
- **Scalability:** Support tiered usage plans and auto‑categorization of past queries  
- **Flexibility:** Admin-configurable backend to switch between different LM services

---

## 3. Target Users
- **Primary:** K‑12 students who need quick homework help  
- **Secondary:** Parents and tutors who assist students

---

## 4. Use Cases
1. **Single Question Help**  
   - User snaps a photo or uploads images (up to 3 images for one question), crops each, and receives answer + explanation.  
2. **Text Submission**  
   - User types or pastes text directly, with optional supporting images.  
3. **History Review**  
   - User views past submissions, grouped by subject or date.

---

## 5. Functional Requirements

| ID   | Requirement                                                                                           |
|------|-------------------------------------------------------------------------------------------------------|
| FR1  | **Image Capture & Upload:** Allow camera or gallery selection.                                         |
| FR2  | **Multi-Image Crop Tool:** Draggable rectangle handles; support up to 3 images **per question**.      |
| FR3  | **Submit to LM:** Send cropped images or text to multimodal LM API.                                   |
| FR4  | **Answer Display:** Show answer and detailed explanation inline.                                       |
| FR5  | **History Log:** Store each query, response, timestamp, and token usage.                               |
| FR6  | **Auto-Categorization:** Call LM to classify subject/topic tags.                                       |
| FR7  | **User Management:** Sign up, login, profile settings, password recovery.                              |
| FR8  | **Subscription Plans:** Tiered plans based on monthly API call limits.                                 |
| FR9  | **In‑App Purchase:** Integrate Google Play and Apple App Store billing.                                |
| FR10 | **Settings:** Language preference, notification controls.                                              |
| FR11 | **Backend Configuration:** Admin-editable config file to switch between commercial LM APIs or self-hosted models. |

---

## 6. Non-Functional Requirements
- **Performance:** Response within 5 seconds for typical queries.  
- **Reliability:** 99.5% uptime for core services.  
- **Security:** TLS encryption; secure token storage; GDPR‑compliant data handling.  
- **Scalability:** Backend autoscaling to handle peak loads.  
- **Accessibility:** Support standard screen readers and high‑contrast modes.

---

## 7. UI/UX Style
- **Minimalist Chat Interface:** Similar to ChatGPT/deepseek—chat bubbles, clean white background.  
- **Crop Overlay:** Semi‑transparent mask with four draggable corner handles.  
- **History Screen:** Card list with thumbnail, title (subject), date, and “View Details” button.  
- **Subscription Screen:** Clear display of plan tiers, usage bars, “Upgrade” buttons.

---

## 8. Technical Architecture
1. **Mobile App (Flutter):** Android & iOS single codebase  
2. **Backend API:**  
   - **Auth Service:** OAuth2 / JWT  
   - **Image Processing Service:** Pre‑crop validation, format conversion  
   - **LM Gateway:** Batch request handler, token usage tracking, config-driven provider selection  
   - **Config Service:** Reads admin-editable YAML/JSON config file specifying LM endpoint, credentials, and model parameters  
   - **Database:** PostgreSQL for user and history data  
   - **Billing Service:** Integration with Stripe (optional) + App Store / Play Store receipts  
3. **Deployment:**  
   - Containerized services orchestrated by Kubernetes  
   - CDN for static assets

---

## 9. Data Flow
1. User captures/uploads image →  
2. App sends image(s) to Image Processing Service →  
3. Cropped images forwarded to LM Gateway (using provider from config) →  
4. LM returns answers + explanations →  
5. Gateway logs token usage, stores history →  
6. App displays results

---

## 10. Security & Privacy
- Enforce HTTPS/TLS for all traffic  
- Store images transiently; auto‑delete after 30 days  
- Encrypt user data at rest  
- Provide “Delete My Data” option

---

## 11. Subscription & Billing
| Plan       | Monthly API Calls | Price (USD) | Over‑usage Rate (per call) |
|------------|-------------------|-------------|-----------------------------|
| Free       | 10                | $0          | $0.3                       |
| Standard   | 100               | $19.99       | $0.3                       |
| Pro        | 500               | $39.99      | $0.2                       |

- Integrate in‑app purchases via Google Play Billing and Apple In-App Purchase.  
- Display current usage in app; alert at 80% of quota.

---

## 12. Future Enhancements
- **Collaborative Study Groups:** Shared history and Q&A sessions  
- **Voice Input:** Speak questions instead of typing or cropping  
- **Handwriting Recognition:** Auto‑detect handwritten questions without manual cropping  
- **Gamification:** Points and badges for frequent learning  
