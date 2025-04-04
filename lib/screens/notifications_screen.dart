import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final List<NotificationItem> notifications = [
    NotificationItem(
      title: "New Test Result Uploaded",
      description: "Complete Blood Count results now available",
      time: "10 mins ago",
      icon: Icons.assignment,
      isRead: false,
    ),
    NotificationItem(
      title: "Appointment Reminder",
      description: "Annual checkup scheduled for tomorrow 10AM",
      time: "2 hours ago",
      icon: Icons.calendar_today,
      isRead: true,
    ),
    // Add more notifications
  ];

  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        actions: [
          IconButton(
            icon: Icon(Icons.checklist),
            onPressed: () => _markAllAsRead(),
            tooltip: "Mark all as read",
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: notifications[index].isRead 
                ? Colors.white 
                : Colors.blue[50],
            child: ListTile(
              leading: Icon(
                notifications[index].icon,
                color: Colors.blue[700],
              ),
              title: Text(
                notifications[index].title,
                style: TextStyle(
                  fontWeight: notifications[index].isRead 
                      ? FontWeight.normal 
                      : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notifications[index].description),
                  SizedBox(height: 4),
                  Text(
                    notifications[index].time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              trailing: !notifications[index].isRead
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () => _handleNotificationTap(index),
            ),
          );
        },
      ),
    );
  }

  void _markAllAsRead() {
    // Implementation to mark all notifications as read
  }

  void _handleNotificationTap(int index) {
    // Handle notification tap based on type
  }
}

class NotificationItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final bool isRead;

  NotificationItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.isRead,
  });
}