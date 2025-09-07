import Flutter
import UIKit


@main
@objc class AppDelegate: FlutterAppDelegate {

    private var coreMotionAggregator: CoreMotionAggregator?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let nativeChannel = FlutterMethodChannel(name: "com.example.health_sample",
                                             binaryMessenger: controller.binaryMessenger)
      nativeChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        
        switch call.method {
        case "openPrivacyPolicy":
          print("openPrivacyPolicy called")
        default:
            print("not implemented")
          result(FlutterMethodNotImplemented)
        }
      })
      
      coreMotionAggregator = CoreMotionAggregator()
      coreMotionAggregator?.fetchPedometerData()
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    

}
