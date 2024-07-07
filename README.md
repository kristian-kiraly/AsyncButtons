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

Custom Labels (SwiftUI):

```swift
struct ContentView: View {
    var body: some View {
        AsyncButton { completion in
            Task {
                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                    completion()
                } catch {
                    
                }
            }
        } label: {
            Text("Test")
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.black)
                }
        }
        .asyncButtonStyle(PinwheelAsyncButtonStyle())
    }
}

struct PinwheelAsyncButtonStyle: AsyncButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                PinwheelAnimationView()
                    .padding(10)
                    .opacity(configuration.isLoading ? 1 : 0)
                    .animation(.default, value: configuration.isLoading)
            }
    }
}


struct PinwheelAnimationView: View {
    @State private var angle: Double = 0
    var body: some View {
        Circle()
            .fill(AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red], center: .center))
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

```

Custom Labels (UIKit):

```swift


class BlankViewController: UIViewController {

    ...

    @IBAction func press(sender: UIButton) {
        let blue = UIView(frame: .init(origin: .zero, size: sender.frame.size))
        blue.backgroundColor = .blue
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.color = .green
        spinner.center = blue.center
        blue.addSubview(spinner)
        sender.performAsyncAction(customOverlay: blue) { completion in
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
