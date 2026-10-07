# Project Guidelines & Rules

## Home Screen & UI Constraints
- **Legal Awareness Main Section**: The "Legal Awareness" section is a permanent, dedicated parent category on the Home Screen below Quick Actions.
  - On the Home Screen, it displays as ONE parent card ("Legal Awareness: Rights, rules & citizen protections") that navigates to the dedicated `LegalAwarenessScreen`.
  - The dedicated `LegalAwarenessScreen` dynamically renders all enabled citizen awareness categories from `LegalAwarenessData.activeItems` (initially `Emergency Rights Guide`, `Indian Railway Rules & Fines`, and `Traffic Rules & Driver Rights`).
  - Scalability: All future citizen awareness topics (e.g., Airline & Aviation Laws, Airport Rights, Tenant & Rental Rules, Consumer Rights, Patient Rights, Workplace Rights) MUST be added inside `LegalAwarenessData.items`. They will automatically render inside the `LegalAwarenessScreen` without modifying the Home screen layout. Do NOT create separate sections or individual cards on the Home screen for each topic.
  - "Legal Awareness" and its individual topics must NOT be placed inside the "More" menu, nor duplicated inside More or Quick Actions.
- **Quick Actions Section**: Do NOT add any new cards, items, or actions to the `Quick Actions` section on the Home Screen (`legalguide_app/lib/screens/home_screen.dart`) unless the user explicitly asks and approves it ("yes").
- **No Duplicate Features**: Avoid duplicating the same feature/topic across multiple sections (e.g., in both Quick Actions and Legal Awareness). Keep each feature in one dedicated location.

## Deployment & Device Updates
- **Always Update on Mobile Device**: Whenever new features, UI updates, or fixes are completed in the app, always deploy/install the updated build to the user's connected mobile phone so they can immediately test the new features on their device.
- **Device Privacy & Scope**: NEVER touch, toggle, or change phone system settings (such as auto-rotate, screen rotation, volume, or notifications). Access and interact ONLY with the LegalGuide app (`com.example.legalguide_app`). Do NOT access, open, or inspect any other app, file, or setting on the user's phone.

