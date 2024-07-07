// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public extension UIButton {
    func performAsyncAction(customOverlay: UIView? = nil, action: @escaping () async -> ()) {
        Task {
            startLoading(customOverlay: customOverlay)
            await action()
            endLoading()
        }
    }
    
    func performAsyncAction(customOverlay: UIView? = nil, action: @escaping (@escaping () -> ()) -> ()) {
        Task {
            startLoading(customOverlay: customOverlay)
            await withCheckedContinuation { continuation in
                action {
                    continuation.resume()
                }
            }
            endLoading()
        }
    }
    
    private var loadingOverlayTag: Int {
        5917737
    }
    
    private func startLoading(customOverlay: UIView? = nil) {
        self.isUserInteractionEnabled = false
        
        let loadingOverlay: UIView
        if let customOverlay {
            loadingOverlay = customOverlay
        } else {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.color = .white
            spinner.startAnimating()
            loadingOverlay = spinner
        }
        
        loadingOverlay.tag = loadingOverlayTag
        
        loadingOverlay.alpha = 0
        
        self.addSubview(loadingOverlay)
        
        NSLayoutConstraint.activate([
            loadingOverlay.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            loadingOverlay.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
        
        UIView.animate(withDuration: 0.35) {
            self.alpha = self.alpha / 2
            loadingOverlay.alpha = 1
        }
    }
    
    private func endLoading() {
        let spinner = self.subviews.last(where: {$0.tag == self.loadingOverlayTag})
        
        UIView.animate(withDuration: 0.35) {
            self.alpha = self.alpha * 2
            spinner?.alpha = 0
        } completion: { _ in
            spinner?.removeFromSuperview()
            self.isUserInteractionEnabled = true
        }
    }
}

public struct AsyncButton<Label: View>: View {
    let action: () async -> ()
    @ViewBuilder let label: () -> Label
    
    @State private var isLoading = false
    private let externalIsLoading: Bool
    
    @Environment(\.asyncButtonStyle) private var style: any AsyncButtonStyle
    
    public init(action: @escaping () async -> (), @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
        self.externalIsLoading = false
    }
    
    public init(action: @escaping (@escaping () -> ()) -> (), @ViewBuilder label: @escaping () -> Label) {
        self.action = {
            await withCheckedContinuation { continuation in
                action {
                    continuation.resume()
                }
            }
        }
        self.label = label
        self.externalIsLoading = false
    }
    
    public init(isLoading: Bool, action: @escaping () -> (), @ViewBuilder label: @escaping () -> Label) {
        self.externalIsLoading = isLoading
        self.label = label
        self.action = {
            action()
        }
    }
    
    public var body: some View {
        if #available(iOS 17.0, *) {
            button
                .onChange(of: externalIsLoading) { _, newValue in
                    self.isLoading = newValue
                }
        } else {
            button
                .onChange(of: externalIsLoading) { newValue in
                    self.isLoading = newValue
                }
        }
    }
    
    private var button: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            AnyView(
                style.makeBody(configuration:.init(
                    isPressed: false,
                    isLoading: isLoading,
                    label: AnyView(label()))))
        }
        .disabled(isLoading)
    }
}

public protocol AsyncButtonStyle {
    associatedtype Body: View
    func makeBody(configuration: Self.Configuration) -> Body
    
    typealias Configuration = AsyncButtonStyleConfiguration
}

public struct AsyncButtonStyleConfiguration {
    public let isPressed: Bool
    public let isLoading: Bool
    public let label: AnyView
    
    public init(isPressed: Bool, isLoading: Bool, label: AnyView) {
        self.isPressed = isPressed
        self.isLoading = isLoading
        self.label = label
    }
}

public struct DefaultAsyncButtonStyle: AsyncButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .opacity(configuration.isLoading ? 0.5 : 1)
            Group {
                if #available(iOS 15.0, *) {
                    ProgressView()
                        .tint(.white)
                } else {
                    ProgressView()
                        .accentColor(.white)
                }
            }
            .opacity(configuration.isLoading ? 1 : 0)
        }
        .animation(.default, value: configuration.isLoading)
    }
}

public extension View {
    func asyncButtonStyle<S: AsyncButtonStyle>(_ style: S) -> some View {
        self
            .environment(\.asyncButtonStyle, style)
    }
}

public struct AsyncButtonStyleKey: EnvironmentKey {
    public static let defaultValue: any AsyncButtonStyle = DefaultAsyncButtonStyle()
}

public extension EnvironmentValues {
    var asyncButtonStyle: any AsyncButtonStyle {
        get { self[AsyncButtonStyleKey.self] }
        set { self[AsyncButtonStyleKey.self] = newValue }
    }
}

public struct AnyAsyncButtonStyle: AsyncButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    
    public init<S: AsyncButtonStyle>(_ style: S) {
        self._makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
