import '../models/user_profile.dart';
import '../models/activity.dart';
import '../models/join_request.dart';
import '../models/message.dart';
import '../models/expense.dart';
import '../models/poll.dart';
import '../models/notification_item.dart';

class MockData {
  static final UserProfile currentUser = UserProfile(
    id: "user_me",
    fullName: "Mayank Thakkar",
    username: "mayank",
    email: "mayank@tribex.app",
    phone: "+91 98765 43210",
    gender: "Male",
    city: "Indiranagar, Bengaluru",
    bio: "Weekend cricket fanatic, tech builder, and trek enthusiast. Always up for a match or filter coffee!",
    avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80",
    rating: 4.95,
    reliabilityScore: 98.0,
    isVerified: true,
    hasCompletedProfile: true,
    hasCompletedOnboarding: true,
    interests: ["Cricket", "Trek", "Food", "Football", "Tech & Creative"],
    latitude: 12.9784,
    longitude: 77.6408,
  );

  static final UserProfile hostRohan = UserProfile(
    id: "host_rohan",
    fullName: "Rohan Sharma",
    username: "rohans",
    city: "Indiranagar, Bengaluru",
    avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80",
    rating: 4.9,
    reliabilityScore: 100.0,
    isVerified: true,
    latitude: 12.9716,
    longitude: 77.6412,
  );

  static final UserProfile hostAnanya = UserProfile(
    id: "host_ananya",
    fullName: "Ananya Rao",
    username: "ananya_r",
    city: "Koramangala, Bengaluru",
    avatarUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80",
    rating: 5.0,
    reliabilityScore: 100.0,
    isVerified: true,
    gender: "Female",
    latitude: 12.9352,
    longitude: 77.6245,
  );

  static final UserProfile hostVikram = UserProfile(
    id: "host_vikram",
    fullName: "Vikram Malhotra",
    username: "vikram_m",
    city: "HSR Layout, Bengaluru",
    avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80",
    rating: 4.8,
    reliabilityScore: 94.0,
    isVerified: false,
    latitude: 12.9121,
    longitude: 77.6446,
  );

  static final UserProfile hostPriya = UserProfile(
    id: "host_priya",
    fullName: "Priya Menon",
    username: "priyam",
    city: "Whitefield, Bengaluru",
    avatarUrl: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80",
    rating: 4.95,
    reliabilityScore: 99.0,
    isVerified: true,
    gender: "Female",
    latitude: 12.9698,
    longitude: 77.7500,
  );

  static List<Activity> getInitialActivities() {
    return [];
  }

  static List<Message> getInitialMessages() {
    final now = DateTime.now();
    return [
      Message(
        id: "msg_1",
        activityId: "act_1",
        senderId: "host_rohan",
        text: "Hey everyone! Turf is confirmed from 7:00 PM to 9:00 PM at Play Arena. Pitch is fast, so bring rubber studs or running shoes.",
        createdAt: now.subtract(const Duration(hours: 2)),
        sender: hostRohan,
      ),
      Message(
        id: "msg_2",
        activityId: "act_1",
        senderId: "user_me",
        text: "Sounds great Rohan! I'll bring two extra tennis balls as well.",
        createdAt: now.subtract(const Duration(hours: 1, minutes: 40)),
        sender: currentUser,
      ),
      Message(
        id: "msg_3",
        activityId: "act_1",
        senderId: "host_rohan",
        text: "POLL:poll_1",
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        sender: hostRohan,
      ),
      Message(
        id: "msg_4",
        activityId: "act_1",
        senderId: "host_rohan",
        text: "EXPENSE:exp_1",
        createdAt: now.subtract(const Duration(minutes: 30)),
        sender: hostRohan,
      ),
      Message(
        id: "msg_5",
        activityId: "act_1",
        senderId: "user_me",
        text: "Just made the payment via UPI! See you all on the field 🏏",
        createdAt: now.subtract(const Duration(minutes: 15)),
        sender: currentUser,
      ),
    ];
  }

  static List<Expense> getInitialExpenses() {
    return [
      Expense(
        id: "exp_1",
        activityId: "act_1",
        creatorId: "host_rohan",
        creatorName: "Rohan Sharma",
        description: "Turf Booking + Match Balls & Gatorade",
        totalAmount: 1500.0,
        upiId: "rohan@okhdfcbank",
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        members: [
          ExpenseMember(
            userId: "host_rohan",
            name: "Rohan Sharma",
            amount: 250,
            isPaid: true,
          ),
          ExpenseMember(
            userId: "user_me",
            name: "Mayank Thakkar",
            amount: 250,
            isPaid: true,
          ),
          ExpenseMember(
            userId: "user_karan",
            name: "Karan Verma",
            amount: 250,
            isPaid: false,
          ),
          ExpenseMember(
            userId: "user_sneha",
            name: "Sneha Patil",
            amount: 250,
            isPaid: true,
          ),
          ExpenseMember(
            userId: "user_rahul",
            name: "Rahul Jain",
            amount: 250,
            isPaid: false,
          ),
          ExpenseMember(
            userId: "user_amit",
            name: "Amit Joshi",
            amount: 250,
            isPaid: false,
          ),
        ],
      ),
    ];
  }

  static List<Poll> getInitialPolls() {
    return [
      Poll(
        id: "poll_1",
        activityId: "act_1",
        creatorId: "host_rohan",
        question: "How many overs per innings do we want to play?",
        createdAt: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 20),
        ),
        options: [
          PollOption(
            id: "opt_1",
            text: "8 Overs match",
            voterIds: ["host_rohan", "user_karan"],
          ),
          PollOption(
            id: "opt_2",
            text: "10 Overs match",
            voterIds: ["user_me", "user_sneha", "user_rahul"],
          ),
          PollOption(
            id: "opt_3",
            text: "12 Overs match",
            voterIds: ["user_amit"],
          ),
        ],
      ),
    ];
  }

  static List<NotificationItem> getInitialNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: "notif_1",
        userId: "user_me",
        title: "Spot Confirmed!",
        body: "Rohan Sharma accepted your request to join Box Cricket 6-a-side match.",
        activityId: "act_1",
        type: NotificationType.requestAccepted,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: "notif_2",
        userId: "user_me",
        title: "New Join Request",
        body: "Ananya Rao requested to join your plan Acoustic Jam Session.",
        activityId: "act_4",
        type: NotificationType.joinRequest,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationItem(
        id: "notif_3",
        userId: "user_me",
        title: "New Match in Indiranagar",
        body: "A new cycling event was scheduled near your saved location.",
        activityId: "act_6",
        type: NotificationType.eventMatch,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<JoinRequest> getInitialJoinRequests() {
    return [];
  }
}
