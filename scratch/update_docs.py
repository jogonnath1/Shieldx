import os

def update_part_10():
    file_path = r'f:\Shieldx\Project Documentations\PART_10_Widgets.md'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replacements
    replacements = {
        '### 10.2.4 `FilterBottomSheetContent`': '### 10.2.4 `FilterBottomSheetContent`\n\n**File**: `lib/common/presentation/widgets/user/filter_bottom_sheet_content.dart`',
        '### 10.2.5 `FilterChipWidget`': '### 10.2.5 `FilterChipWidget`\n\n**File**: `lib/common/presentation/widgets/user/filter_chip_widget.dart`',
        '### 10.2.6 `StationMarkerWidget`': '### 10.2.6 `StationMarkerWidget`\n\n**File**: `lib/common/presentation/widgets/user/station_marker_widget.dart`',
        '### 10.2.7 `GpsUserLocationMarker`': '### 10.2.7 `GpsUserLocationMarker`\n\n**File**: `lib/common/presentation/widgets/user/gps_user_location_marker.dart`',
        '### 10.2.8 `UserLocationHighlightMarker`': '### 10.2.8 `UserLocationHighlightMarker`\n\n**File**: `lib/common/presentation/widgets/user/user_location_highlight_marker.dart`',
        '### 10.2.9 `QuickActionCard`': '### 10.2.9 `QuickActionCard`\n\n**File**: `lib/common/presentation/widgets/user/quick_action_card.dart`',
        '### 10.2.10 `RecentComplaintCard`': '### 10.2.10 `RecentComplaintCard`\n\n**File**: `lib/common/presentation/widgets/user/recent_complaint_card.dart`',
        '### 10.2.11 `DeletedComplaintCard`': '### 10.2.11 `DeletedComplaintCard`\n\n**File**: `lib/common/presentation/widgets/user/deleted_complaint_card.dart`',
        '### 10.2.12 `DeletedNotificationCard`': '### 10.2.12 `DeletedNotificationCard`\n\n**File**: `lib/common/presentation/widgets/user/deleted_notification_card.dart`',
    }
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    # Insert 10.1.6 EvidenceItemWidget
    evidence_insert = """### 10.1.6 `EvidenceItemWidget`

**File**: `lib/common/presentation/widgets/common/evidence_item_widget.dart`

A reusable widget to display a single piece of evidence (image or file) in grids. Includes remove functionality and upload progress indication.

---

## 10.2 User Widgets"""
    content = content.replace('## 10.2 User Widgets', evidence_insert)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def update_part_3():
    file_path = r'f:\Shieldx\Project Documentations\PART_3_Core.md'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    date_time_insert = """## 3.9 `common/core/utils/date_time_extensions.dart`

**File**: `lib/common/core/utils/date_time_extensions.dart`

Provides extensions on `DateTime` for easy formatting (e.g. `TimeAgo` string representations, formatted date strings) used in UI components.

---

*Next:"""
    content = content.replace('*Next:', date_time_insert)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == "__main__":
    update_part_10()
    update_part_3()
    print("Updated PART 10 and PART 3")
