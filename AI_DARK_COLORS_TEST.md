# AI Message Dark Color Options Test

## Dark Color Examples with Light Text

The following dark colors have been added to the AI message color palette. Each color automatically uses light text for optimal readability:

### Dark Color Palette

1. **Dark Gray (#1E1E1E)**
   - Modern, professional appearance
   - Excellent for dark theme users
   - High contrast with white text

2. **Dark Blue-Gray (#2D3748)**
   - Sophisticated, tech-inspired look
   - Balances blue undertones with neutrality
   - Great for business/professional contexts

3. **Dark Charcoal (#1A202C)**
   - Deep, rich appearance
   - Ultimate readability with light text
   - Minimal eye strain

4. **Dark Blue (#2A4365)**
   - Deep navy blue aesthetic
   - Professional and trustworthy feel
   - Excellent contrast ratios

5. **Dark Purple (#553C9A)**
   - Creative and modern appeal
   - Unique alternative to standard colors
   - Good for AI personality expression

6. **Dark Green (#1F4B3F)**
   - Natural, calming appearance
   - Alternative to traditional light colors
   - Great for eco-conscious themes

7. **Dark Orange (#744210)**
   - Warm, inviting feel
   - Distinctive from other options
   - Good for friendly AI interactions

8. **Dark Teal (#065F46)**
   - Professional cyan-green hybrid
   - Modern tech aesthetic
   - Excellent readability

## Automatic Text Contrast

The message bubble widget automatically calculates the appropriate text color:

```dart
Color _getContrastColor(Color backgroundColor) {
  final luminance = backgroundColor.computeLuminance();
  return luminance > 0.5 ? Colors.black87 : Colors.white;
}
```

### Benefits of Dark AI Colors:

- **Dark Theme Compatibility**: Perfect for users who prefer dark interfaces
- **Reduced Eye Strain**: Dark backgrounds can be easier on the eyes in low-light conditions
- **Modern Aesthetic**: Provides a sleek, contemporary look
- **Personality Expression**: Allows AI responses to have more character
- **Theme Variety**: Gives users more options to match their preferred style

### Usage Recommendations:

- **Light Environments**: Use light AI colors for better readability in bright conditions
- **Dark Environments**: Use dark AI colors for reduced glare and eye strain
- **Personal Preference**: Choose based on individual style and comfort
- **Accessibility**: Both options maintain WCAG contrast standards

The smart contrast calculation ensures that regardless of the chosen background color, the text will always be clearly readable.
