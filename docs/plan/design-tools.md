# Design Tool Decision

Last verified: September 10, 2026

## Decision

Use **Penpot** as the primary UI design and prototype tool, with **Excalidraw** for early user flows and information architecture.

This combination is free enough for the project to operate without a paid subscription. It also keeps design work independent from a proprietary AI provider.

| Tool | Role | Free status | Decision |
| --- | --- | --- | --- |
| Penpot | Wireframes, UI design, prototypes, components, design tokens, developer inspection | Free cloud plan with core features, up to 8 team members, and up to 10 GB storage; self-hosting is available | Primary tool |
| Excalidraw | User flows, navigation maps, rough sketches, brainstorming | Free browser-based canvas; save files locally because browser storage is not durable | Use for early definition |
| Figma Starter | Alternative UI design and prototyping | Free plan exists, but AI uses limited credits and the plan is not unlimited | Do not make it a dependency |
| Canva Free | Visual assets and presentations | Free plan exists, but premium and AI capabilities are plan- and allowance-dependent | Not the primary product-design tool |
| Google Stitch or similar AI generators | Prompt-to-UI exploration and high-fidelity direction | Availability, quotas, export quality, and terms can change | Active for the visual redesign (see below); still not a dependency |

## Stitch Usage (Visual Redesign)

Google Stitch is now the active source for the high-fidelity direction of the visual
redesign (`docs/plan/design-redesign-plan.md`). The project is "App Ciudadanía USA"
(project ID `13329010267888174190`), owned by the user and read through the `stitch` MCP.

- The MCP exposes the project even though `list_mcp_resources` returns nothing; read it via
  `tools.stitch.list_projects()` → `list_screens({ projectId })` → the screen's HTML or PNG.
- Two screens expose interactive HTML (Home "Exam Readiness", Flashcards "Active Study
  Session"); the rest are PNG screenshots.
- The app must stay implementable from this repository's documented tokens without the AI
  tool. Stitch is the design reference, not the content or rules source of truth.

## What “100% Free” Means Here

No hosted AI design product should be treated as unlimited or permanently free. Free plans can change, impose usage quotas, require an account, or limit exports. The project therefore requires that:

- Core user flows and screen specifications remain readable in Markdown.
- Design files can be exported or backed up locally.
- The app can be implemented from the documented design system without an AI tool.
- No paid AI subscription is required to complete any phase.
- AI-generated output is reviewed manually and is never accepted as the source of truth for accessibility, USCIS rules, or interaction behavior.

## Phase 0.5 Workflow

1. Use Excalidraw to map the navigation and the main learning journeys.
2. Use Penpot to create low-fidelity wireframes for every screen in the inventory.
3. Define typography, color tokens, spacing, control states, and accessibility rules in Penpot.
4. Prototype only the highest-risk flows: onboarding, flashcard study, mock test, and speech fallback.
5. Export a local backup and record the final decisions in the repository before implementation.

## References

- [Penpot pricing](https://penpot.app/pricing)
- [Penpot AI workflows](https://penpot.app/ai/ai-workflows)
- [Excalidraw](https://excalidraw.com/)
- [Figma pricing](https://www.figma.com/pricing/)
- [Canva pricing](https://www.canva.com/pricing/)
