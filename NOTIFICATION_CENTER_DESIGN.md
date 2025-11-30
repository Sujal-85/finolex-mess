# FAMT Mess App - Notification Center Design

## Overview
Sleek, modern, and highly organized Notification Center for the FAMT Mess App following Google Material 3 with soft Neumorphism design principles. Provides a clean, informative, and lightning-fast scanning experience.

## Design Specifications

### Color Palette
- Primary: Royal Blue (#1E88E5)
- Accent: Bright Orange (#FF9800)
- Light Mode Background: #F5F7FA
- Dark Mode Background: #121212
- Card Surfaces: White (light) / Charcoal Grey (dark)

### Header Section
- Title: "Notifications" in bold Poppins font
- Settings icon on the right for notification preferences
- Sticky top bar with subtle shadow when scrolling
- Clean, minimalist design with ample padding

### Category Filters
Horizontal chip filters for:
- All (default)
- Mess
- Payment
- News
- Urgent

Active chip features:
- Royal Blue fill (#1E88E5) with white text
- Subtle shadow for depth
- Smooth transition animations

Inactive chips:
- Grey outline with appropriate text color
- Neumorphic styling matching the overall design

### Notification List
Each notification appears as a modern, elevated card with:
- Leading icon based on notification type:
  - Mess → restaurant icon
  - Payment → wallet icon
  - News → article icon
  - Urgent → warning icon
- Bold title and descriptive subtitle
- Timestamp with relative time formatting ("2m ago", "Yesterday")
- "New" badge for unread important notifications
- Rounded corners (20px) for consistent neumorphic look

#### Interaction Features
- Soft elevation on card tap
- Ripple effect for tactile feedback
- Staggered slide-in animation for list items
- Pull-to-refresh with wave animation
- Red dot indicator for unread notifications
- Transformer-style icon morphing for urgent alerts

#### Gestures
- Swipe right → mark as read
- Swipe left → delete notification
- Tap → open details screen

### Grouping System
Notifications are grouped under time-based headers:
- Today
- Yesterday
- This Week
- Older

Headers remain sticky during scrolling for easy navigation.

### Dark Mode Implementation
- Deep black background (#121212)
- Dark neumorphic cards with charcoal grey surfaces
- White text with 90-95% opacity for comfortable reading
- Neon-style accents for category chips to maintain vibrancy
- Royal Blue highlights (#1E88E5) remain vibrant in dark mode

### Empty State
When no notifications exist in the selected category:
- Bell sleeping Lottie animation
- "No notifications yet" message
- Subtext: "We'll notify you when something important happens"
- Light blue tint background for visual comfort

## Technical Implementation

### Components
1. **Notification Model** - Defines notification structure and types
2. **Notification Service** - Manages notification state and operations
3. **Notification Center Screen** - Main UI component with all features

### Animations & Micro-Interactions
- Smooth slide + fade animation when switching categories
- Staggered slide-in animation for notification list items
- Pull-to-refresh with Lottie wave animation
- Dismissible notifications with visual feedback
- Ripple effects on taps
- Morphing icons for urgent alerts

### Responsive Design
- Adapts to both light and dark themes
- Consistent neumorphic styling across components
- Proper spacing and sizing for mobile devices
- Accessible color contrast in both themes

## Flutter Implementation Details

### Dependencies
- google_fonts: For consistent typography
- provider: For state management
- go_router: For navigation

### Key Widgets
- Custom EmptyStateWidget for empty notifications
- Dismissible for swipe gestures
- AnimatedContainer for smooth transitions
- Consumer for reactive UI updates

### Styling
- NeumorphicStyle class for consistent card styling
- AppColors class for theme-aware color management
- Google Fonts for typography consistency

## File Structure
```
lib/
├── src/
│   ├── models/
│   │   └── notification_model.dart
│   ├── services/
│   │   └── notification_service.dart
│   ├── screens/
│   │   └── notification_center_screen.dart
│   └── utils/
│       └── app_router.dart (updated with new route)
└── main.dart (updated with NotificationService provider)
```