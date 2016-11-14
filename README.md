# HolaCDN.framework

This document describes integration of a native iOS app to HolaCDN.

## Requirements

iOS 7+ or tvOS 9+ required.

At the moment, HolaCDN works with `AVPlayer` or `AVQueuePlayer`, only with `AVURLAsset`+HLS videos. Custom `AVAssetResourceLoaderDelegate` is not yet supported (coming soon).

Note: An [Android version] (https://github.com/hola/android_sdk) is also available.

If you have any questions, email us at cdn-help@hola.org, or skype: holacdn

## Install

### Manually

- Download the latest [release](https://github.com/hola/ios_sdk/releases)

- Add hola-cdn-sdk.xcodeproj into your project

- In your Target, click + in `Linked Frameworks and Libraries`, add `libHolaCDN.a`

### via CocoaPods

- Add the pod into your Podfile:

```
pod "HolaCDN", "~> 1.2.0" # JSContext version (for iOS and tvOS)
```

- Run `$ pod install`

- For any questions about CocoaPods usage, please check [their documentation](http://cocoapods.org/)

## Initialization

- Create a new instance of `HolaCDN`

```swift
let cdn = HolaCDN()
```

- Call the config method with desired parameters
  - `customer`: String – required parameter, your customerId
  - `zone`: String? – optional parameter to force zone selection. In case of `nil` will be selected automatically according to your customer's HolaCDN config
  - `mode`: String? – optional parameter to force cdn mode selection. In case of `nil` will be selected automatically according to your customer's HolaCDN config; supported options are: `nil`, `"stats"`, `"cdn"`.

```swift
cdn.configWithCustomer("your_customer_id", usingZone: nil, andMode: nil)
```

- Create a class which conforms to `HolaCDNDelegate` protocol to
handle some HolaCDN callbacks:

```swift
protocol HolaCDNDelegate: NSObjectProtocol {
    optional func cdnDidLoaded(cdn: HolaCDN) -> Void
    optional func cdnDidAttached(cdn: HolaCDN) -> Void
    optional func cdnDidDetached(cdn: HolaCDN) -> Void
    optional func cdnStateChanged(cdn: HolaCDN, toState state: String) -> Void
    optional func cdnExceptionOccured(cdn: HolaCDN, withError: NSError) -> Void
}
```

- Set the delegate and call `load` method

```swift
// in case if you have implemented the protocol for the current ViewController
cdn.delegate = self
try! cdn.load() // could throw an error in case if no "customerId" provided with cdn.config method
```

- Loading occurs asynchronically. During that process some delegate
methods could be called:

  - `cdnDidLoaded(cdn: HolaCDN) -> Void`: when HolaCDN code is loaded & inited
  - `cdnExceptionOccured(cdn: HolaCDN, withError: NSError) -> Void`:
when something goes wrong while executing HolaCDN code

- How to check `HolaCDN` state:

  - `cdn.get_mode(completionBlock: (String?) -> Void)`: Async method, returns current cdn mode into completionBlock:

    - `"loading"` – CDN js code is loading
    - `"detached"` – CDN is loaded, not attached to a player
    - `"disabled"` – CDN is in automatic mode and disabled for current config
    - `"stats"` – CDN is attached and working in stats-only mode
    - `"cdn"` – CDN is attached and working in cdn mode

  - via Safari inspector:
    - Enable Safari developer mode in the preferences
    - Run your app in a Simulator or connected device
      - To enable this option in your device, look into Settings -> Safari -> Advanced -> Web-inspector
    - Find the app in Safari -> Develop -> Simulator (or the device name) menu
    - in the dev tools console, run `hola_cdn.get_stats()`
      - you should see detailed cdn stats at the moment
      - if you see `undefined` – it means cdn is not working properly

## Attach

Attachment is required to activate HolaCDN features. Example:

```swift
let myAVPlayer = AVPlayer(URL: url)
cdn.attach(myAVPlayer)
```

`myAVPlayer` instance can be used as a regular AVPlayer object.

## Example

### Swift

```swift
import HolaCDN

class PlayerViewController: AVPlayerViewController, HolaCDNDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let cdn = HolaCDN()
        cdn.configWithCustomer(customer: "demo", usingZone: nil, andMode: "cdn")
        cdn.delegate = self

        let url = NSURL(string: "https://example.com/your/video.m3u8")!
        self.player = AVPlayer(URL: url)

        try! cdn.load()
    }

    func cdnDidLoaded(cdn: HolaCDN) {
        NSLog("cdn did loaded")

        cdn.attach(self.player!)
    }

    func cdnDidAttached(cdn: HolaCDN) {
        NSLog("cdn did attached! \(cdn.get_mode())")
    }
}
```

### Objective-C

```objc
#import "hola_cdn_sdk.h"

@implementation PlayerViewController

HolaCDN* cdn;
AVPlayer* player;

- (void)viewDidLoad {
    [super viewDidLoad];

    cdn = [HolaCDN new];
    [cdn setDelegate:self];
    [cdn configWithCustomer:@"demo" usingZone:nil andMode:@"cdn"];

    NSURL *url = [NSURL URLWithString:@"https://example.com/your/video.m3u8"];
    player = [AVPlayer playerWithURL:url];

    NSError *err = [NSError alloc];
    [cdn load:&err];
}

-(void)cdnDidLoaded:(HolaCDN *)cdn {
    [cdn attach:player];
}

-(void)cdnDidAttached:(HolaCDN *)cdn {
    NSLog(@"cdn did attached! %@", [cdn get_mode]);
}

@end
```
