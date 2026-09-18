# Lockscreen Brightness Slider 16

Adds a brightness slider between the iOS 16 Lock Screen flashlight and camera buttons, with an option to hide the DND / Focus name shown in the same area.

## DND / Focus hook

The text is rendered by an `SBUILegibilityLabel` inside `NCNotificationListCountIndicatorView`. The tweak hides only the label whose accessibility identifier begins with `focus-text-`.

To restore the stock text in the source, remove the `NCNotificationListCountIndicatorView` hook and its Focus-label helper functions from `Tweak.xm`.

Rootless iOS 16 / Dopamine / ElleKit.
