# Fitness Projects Design System

This document serves as the Single Source of Truth (SSOT) for the design system used across both `fitness-app` (React Native/Expo) and `fitness-web` (Vite/React/MUI). 

## 1. Color Palette

### Base Colors (Material UI equivalent)
- **Primary:** `#1976d2` (Light: `#42a5f5`, Dark: `#1565c0`)
- **Secondary:** `#9c27b0` (Light: `#ba68c8`, Dark: `#7b1fa2`)
- **Error:** `#d32f2f`
- **Success:** `#2e7d32` (Light: `#4caf50`)
- **Warning:** `#ed6c02`
- **Info:** `#0288d1`

### Backgrounds & Surfaces
- **Light Mode:** 
  - Default Background: `#f4f6f8`
  - Paper/Surface: `#ffffff`
- **Dark Mode:**
  - Default Background: `#0a0e1a`
  - Paper/Surface: `#111827`

### Text Colors
- **Light Mode:** 
  - Primary: `#1a2027`
  - Secondary: `#637381`
- **Dark Mode:** 
  - Primary: `#e8eaf0`
  - Secondary: `#8899aa`

## 2. Block/Card Specific Colors
When rendering specific types of workout blocks or timeline items, use the following distinct colors to highlight their type:
- **WARMUP:** Red (Rojo) - e.g. `#d32f2f` or `error.main`
- **EMOM:** Blue (Azul) - e.g. `#1976d2` or `primary.main`
- **AMRAP:** Yellow (Amarillo) - e.g. `#fbc02d` or similar high-contrast yellow
- **POWER:** Light Gray (Gris claro) - e.g. `#8A8A8A` or `#9e9e9e`
- **TABATA:** Purple (Violeta) - e.g. `#9c27b0` or `secondary.main`
- **SEMANAS (Weeks):** Green (Verde) - e.g. `#2e7d32` or `success.main`

## 3. Typography
We use a two-font system. 
- **Font Family (Headings):** `"Bebas Neue", sans-serif` (letterSpacing: `0.05em`) -> h1, h2, h3, h4, h5
- **Font Family (Body/Other):** `"Inter", "Roboto", "Helvetica", "Arial", sans-serif`
- **Font Weights:** Regular (400), Button (600, `0.04em` letter-spacing), Table Headers (700, uppercase, `0.1em` spacing).

## 4. Spacing & Shape
- **Base Spacing:** 8px scale. (1 = 8px, 2 = 16px, 3 = 24px, etc.)
- **Base Border Radius:** 10px (e.g., Modals, Dialogs, General Paper)
- **Cards Border Radius:** 12px
- **Buttons / Inputs Border Radius:** 8px
- **Chips / Tooltips Border Radius:** 6px

## 5. UI Elements
- **Borders/Dividers:** 
  - Light mode: `rgba(0,0,0,0.09)` (Cards: `rgba(0,0,0,0.07)`)
  - Dark mode: `rgba(255,255,255,0.09)` (Cards: `rgba(255,255,255,0.07)`)

---
*Note for AI Agents: Always consult these values before generating or modifying UI components in fitness-app or fitness-web.*
