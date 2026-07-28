import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  private var reminderChannel: FlutterMethodChannel?
  private var liveViewChannel: FlutterMethodChannel?
  private var widgetChannel: FlutterMethodChannel?
  private var inviteChannel: FlutterMethodChannel?
  private var lastScheduledNotificationId: Int? = nil

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as? FlutterViewController

    // 1. 休息提醒通道
    reminderChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/reminder",
      binaryMessenger: controller!.binaryMessenger
    )
    setupReminderChannel()

    // 2. 实况窗通道（Batch 3 实现，此处占位）
    liveViewChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/liveview",
      binaryMessenger: controller!.binaryMessenger
    )
    setupLiveViewChannel()

    // 3. 桌面卡片通道（Batch 3 实现，此处占位）
    widgetChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/widget",
      binaryMessenger: controller!.binaryMessenger
    )
    setupWidgetChannel()

    // 4. 邀请链接通道
    inviteChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/invite",
      binaryMessenger: controller!.binaryMessenger
    )
    setupInviteChannel()

    // 设置 UNUserNotificationCenter 代理（处理通知点击）
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Reminder Channel

  private func setupReminderChannel() {
    reminderChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "scheduleRestReminder":
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let content = args["content"] as? String,
              let triggerTimeInSeconds = args["triggerTimeInSeconds"] as? Int,
              let notificationId = args["notificationId"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }
        self?.scheduleRestReminder(
          title: title,
          bodyText: content,
          triggerTimeInSeconds: triggerTimeInSeconds,
          notificationId: notificationId,
          result: result
        )
      case "cancelRestReminder":
        let id = self?.lastScheduledNotificationId ?? 1001
        self?.cancelRestReminder(notificationId: id, result: result)
      case "cancelAllReminders":
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func scheduleRestReminder(
    title: String,
    bodyText: String,
    triggerTimeInSeconds: Int,
    notificationId: Int,
    result: @escaping FlutterResult
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = bodyText
    content.sound = .default
    content.userInfo = [
      "targetPage": "training",
      "cardAction": "resume",
      "notificationId": notificationId
    ]

    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: TimeInterval(triggerTimeInSeconds),
      repeats: false
    )

    let request = UNNotificationRequest(
      identifier: "rest_\(notificationId)",
      content: content,
      trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { [weak self] error in
      if let error = error {
        result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
      } else {
        self?.lastScheduledNotificationId = notificationId
        result(notificationId)
      }
    }
  }

  private func cancelRestReminder(notificationId: Int, result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: ["rest_\(notificationId)"]
    )
    result(true)
  }

  // MARK: - LiveView Channel (占位，Batch 3 实现)

  private func setupLiveViewChannel() {
    liveViewChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "startRestLiveView":
        // Batch 3 实现 ActivityKit
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "Live Activities in Batch 3", details: nil))
      case "stopRestLiveView":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Widget Channel (占位，Batch 3 实现)

  private func setupWidgetChannel() {
    widgetChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "pushCardData":
        // 写入 App Group UserDefaults（Batch 3 实现 WidgetKit reload）
        if let jsonData = call.arguments as? String {
          let defaults = UserDefaults(suiteName: "group.com.fp.fitplan")
          defaults?.set(jsonData, forKey: "widgetData")
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Expected JSON string", details: nil))
        }
      case "clearCardData":
        let defaults = UserDefaults(suiteName: "group.com.fp.fitplan")
        defaults?.removeObject(forKey: "widgetData")
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Invite Channel

  private func setupInviteChannel() {
    inviteChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "launchInviteUrl":
        guard let urlString = call.arguments as? String,
              let url = URL(string: urlString) else {
          result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
          return
        }
        DispatchQueue.main.async {
          UIApplication.shared.open(url) { success in
            result(success)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - URL Scheme Handling

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // 处理 fittrack://invite/... URL
    inviteChannel?.invokeMethod("onInviteUrl", arguments: url.absoluteString)
    return true
  }

  // MARK: - UNUserNotificationCenterDelegate

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // 前台也显示通知
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    // 通知点击回传 Flutter
    reminderChannel?.invokeMethod("onCardClick", arguments: userInfo)
    completionHandler()
  }
}
