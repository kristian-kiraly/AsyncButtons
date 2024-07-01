# AsyncButtons

Adding a dead-simple way to add async capability to SwiftUI's Buttons and UIKit's UIButtons by disabling button interaction during an async operation and adding a progress overlay while the action completes.

Usage:

```swift
struct ContentView: View {
    @State private var isLoading = false

    var body: some View {
        AsyncButton {
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
            
            }
        } label: {
            Text("Press me!")
        }
        AsyncButton { completion in
            Task {
                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                    completion()
                } catch {
            
                }
            }
        } label: {
            Text("Completion Block Async")
        }
        AsyncButton(isLoading: isLoading) {
            isLoading = true
            Task {
                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                    isLoading = false
                } catch {
            
                }
            }
        } label: {
            Text("Externally Controlled Loading")
        }
    }
}

class SomeUIViewController: UIViewController {

    @IBAction func buttonPress(sender: UIButton) {
        sender.performAsyncAction {
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
        
            }
        }
    }
    
    @IBAction func completionBlockButtonPress(sender: UIButton) {
        sender.performAsyncAction { completion in
            Task {
                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                    completion()
                } catch {
                    
                }
            }
        }
    }
}
```

