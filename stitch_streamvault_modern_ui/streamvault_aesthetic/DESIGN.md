---
name: StreamVault Aesthetic
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c7c4d7'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#908fa0'
  outline-variant: '#464554'
  surface-tint: '#c0c1ff'
  primary: '#c0c1ff'
  on-primary: '#1000a9'
  primary-container: '#8083ff'
  on-primary-container: '#0d0096'
  inverse-primary: '#494bd6'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#d0bcff'
  on-tertiary: '#3c0091'
  tertiary-container: '#a078ff'
  on-tertiary-container: '#340080'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#e9ddff'
  tertiary-fixed-dim: '#d0bcff'
  on-tertiary-fixed: '#23005c'
  on-tertiary-fixed-variant: '#5516be'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-padding: 24px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

The design system is centered on a "Cinematic Tech" aesthetic, tailored for a high-end video downloader experience. It evokes a sense of premium exclusivity, speed, and digital craftsmanship. The brand personality is sophisticated yet powerful, utilizing a deep, immersive background to make content the primary focus. 

The visual style leans heavily into **Glassmorphism**, employing translucent layers and vibrant background blurs to create a sense of physical depth within a digital space. Emotional responses should range from awe at the fluid visuals to confidence in the tool's performance. Glowing accents and high-fidelity transitions are used to reinforce the "Electric" nature of the service.

## Colors

The palette is anchored by a deep slate-navy foundation to provide maximum contrast for the accent elements. This design system utilizes a signature **Electric Gradient** (Indigo to Cyan) for interactive states, progress indicators, and primary branding elements. 

- **Primary & Secondary:** Used exclusively for high-priority actions and brand-specific flourishes.
- **Surface Colors:** Derived from the base background but lifted through transparency to allow for glass effects.
- **Functional Accents:** Glowing versions of the Indigo and Cyan are used to signify "active" or "downloading" statuses, creating a light-source effect on the dark canvas.

## Typography

This design system employs **Inter** to maintain a clean, systematic, and utilitarian feel that balances the highly expressive visual style. 

- **Hierarchy:** Dramatic scale differences between display titles and body text ensure clarity. 
- **Readability:** Body text uses a slightly lighter weight (400) on the dark background to prevent "haloing," while labels and headers use medium to bold weights to command attention.
- **Tracking:** Tight letter spacing on large headlines creates a "premium" editorial look, while wider tracking on small labels ensures legibility in low-light environments.

## Layout & Spacing

The layout philosophy follows a **fluid grid** model with generous safe areas to maintain a "high-end" airy feel. 

- **Grid:** A 12-column grid for desktop/tablet and a 4-column grid for mobile.
- **Rhythm:** An 8px linear scale is used for all spacing. 
- **Negative Space:** Content groups are separated by larger vertical stacks (32px+) to prevent the glass elements from appearing cluttered. Marginal space is prioritized to keep the focus on centered media content.

## Elevation & Depth

Depth in the design system is achieved through **Backdrop Blurs** and **Stacked Translucency** rather than traditional black shadows.

1.  **Base:** The #0F172A background.
2.  **Surface:** Semi-transparent overlays (rgba 30, 41, 59, 0.7) with a `backdrop-filter: blur(12px)`.
3.  **Borders:** Each card and container must have a 1px solid border using a low-opacity white (rgba 255, 255, 255, 0.1) to define edges against the dark background.
4.  **Inner Glow:** Primary buttons utilize a subtle inner box-shadow and a soft outer drop-shadow of the primary indigo to simulate a neon-piping effect.

## Shapes

The shape language is characterized by oversized, friendly radiuses that soften the technical nature of the app. 

- **Main Containers:** All primary cards and modals use a **24px** corner radius.
- **Interactive Elements:** Buttons and input fields use a **12px** radius to provide a distinct visual difference from the larger layout containers.
- **Icons:** Use a consistent 2px stroke width with slightly rounded terminals to match the typography.

## Components

### Buttons
Primary buttons feature the Electric Indigo to Cyan gradient with white text. They should have a subtle `0 0 15px` outer glow in the primary color when hovered or active. Secondary buttons use the "glass" style with a 1px border.

### Cards
Cards are the hallmark of this design system. They must utilize `backdrop-filter: blur(20px)`, a `24px` radius, and the thin `1px` white border. Content inside cards should be padded at `24px`.

### Progress Bars
Video download progress is displayed using a dual-tone gradient fill. The unfilled portion of the track is a dark, desaturated navy (#1E293B). A small "glow" point should follow the leading edge of the progress indicator.

### Input Fields
Inputs are dark with a `1px` border that transitions to the Cyan accent color when focused. Use a placeholder text color of `rgba(255, 255, 255, 0.4)`.

### Media Thumbnails
Thumbnails should have an inner shadow or gradient overlay on the bottom third to ensure white labels (video titles, duration) remain legible regardless of the video content.