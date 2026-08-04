import UIKit
import Flutter
import UserNotifications
import ActivityKit
import WidgetKit

// Live Activity 的 Attributes 类型。
// 注：RestLiveActivity Widget Extension 尚未接入 Xcode 工程，
// 因此该类型需在主 target 内定义以保证 AppDelegate 可编译。
@available(iOS 16.1, *)
struct RestLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var exerciseName: String
        var remainingSeconds: Int
        var totalRestSeconds: Int
        var restEndTime: Date
    }

    var exerciseName: String
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
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

  // MARK: - LiveView Channel (ActivityKit)

  private func setupLiveViewChannel() {
    liveViewChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startRestLiveView":
        guard let args = call.arguments as? [String: Any],
              let exerciseName = args["exerciseName"] as? String,
              let restSeconds = args["restSeconds"] as? Int,
              let restEndTimeMs = args["restEndTimeMs"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }

        if #available(iOS 16.2, *) {
          self?.startRestLiveView(
            exerciseName: exerciseName,
            restSeconds: restSeconds,
            restEndTimeMs: restEndTimeMs,
            result: result
          )
        } else {
          // 低于 16.2 降级为普通通知
          result(FlutterError(code: "UNAVAILABLE", message: "Live Activities requires iOS 16.2+", details: nil))
        }
      case "stopRestLiveView":
        if #available(iOS 16.1, *) {
          for activity in Activity<RestLiveActivityAttributes>.activities {
            Task {
              await activity.end(dismissalPolicy: .immediate)
            }
          }
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16.2, *)
  private func startRestLiveView(
    exerciseName: String,
    restSeconds: Int,
    restEndTimeMs: Int,
    result: @escaping FlutterResult
  ) {
    let attributes = RestLiveActivityAttributes(exerciseName: exerciseName)
    let restEndTime = Date(timeIntervalSince1970: TimeInterval(restEndTimeMs) / 1000.0)
    let state = RestLiveActivityAttributes.ContentState(
        exerciseName: exerciseName,
        remainingSeconds: restSeconds,
        totalRestSeconds: restSeconds,
        restEndTime: restEndTime
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: restEndTime),
        pushType: nil
      )
      debugPrint("[LiveView] Activity started: \(activity.id)")
      result(true)
    } catch {
      debugPrint("[LiveView] Error starting activity: \(error)")
      result(FlutterError(code: "ACTIVITY_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: - Widget Channel (WidgetKit reload)

  private func setupWidgetChannel() {
    widgetChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "pushCardData":
        if let jsonData = call.arguments as? String {
          let defaults = UserDefaults(suiteName: "group.com.lt.lifttrack")
          defaults?.set(jsonData, forKey: "widgetData")
          // 触发 WidgetKit 刷新
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "FitTrackWidget")
          }
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Expected JSON string", details: nil))
        }
      case "clearCardData":
        let defaults = UserDefaults(suiteName: "group.com.lt.lifttrack")
        defaults?.removeObject(forKey: "widgetData")
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadTimelines(ofKind: "FitTrackWidget")
        }
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
    // I3 修复：路由 fittrack:// URL。
    // - fittrack://action?cardAction=skipRest → reminderChannel.onCardClick
    //   （iOS Live Activity "结束休息"按钮通过 Link 触发）
    // - fittrack://invite/... → inviteChannel.onInviteUrl（既有逻辑）
    if url.scheme == "fittrack" && url.host == "action" {
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let cardAction = components?.queryItems?.first(where: { $0.name == "cardAction" })?.value
      if cardAction == "skipRest" {
        let params: [String: Any] = [
          "targetPage": "training",
          "cardAction": "skipRest"
        ]
        reminderChannel?.invokeMethod("onCardClick", arguments: params)
      }
      return true
    }

    // 处理 fittrack://invite/... URL
    inviteChannel?.invokeMethod("onInviteUrl", arguments: url.absoluteString)
    return true
  }

  // MARK: - UNUserNotificationCenterDelegate

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // 前台也显示通知（.banner 为 iOS 14+ API）
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func userNotificationCenter(
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
