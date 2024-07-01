// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

extension UIButton {
    func performAsyncAction(action: @escaping () async -> ()) {
        Task {
            startLoading()
            await action()
            endLoading()
        }
    }
    
    func performAsyncAction(action: @escaping (@escaping () -> ()) -> ()) {
        Task {
            startLoading()
            await withCheckedContinuation { continuation in
                action {
                    continuation.resume()
                }
            }
            endLoading()
        }
    }
    
    private var spinnerTag: Int {
        5917737
    }
    
    private func startLoading() {
        self.isUserInteractionEnabled = false
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        spinner.tag = spinnerTag
        
        spinner.alpha = 0
        spinner.color = .white
        
        self.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
        
        UIView.animate(withDuration: 0.35) {
            self.alpha = self.alpha / 2
            spinner.alpha = 1
        }
        
        spinner.startAnimating()
    }
    
    private func endLoading() {
        
        let spinner = self.subviews.last(where: {$0.tag == self.spinnerTag})
        
        UIView.animate(withDuration: 0.35) {
            self.alpha = self.alpha * 2
            spinner?.alpha = 0
        } completion: { _ in
            spinner?.removeFromSuperview()
            self.isUserInteractionEnabled = true
        }
    }
}

struct AsyncButton<Label: View>: View {
    let action: () async -> ()
    @ViewBuilder let label: () -> Label
    
    @State private var isLoading = false
    private let externalIsLoading: Bool
    
    init(action: @escaping () async -> (), @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
        self.externalIsLoading = false
    }
    
    init(action: @escaping (@escaping () -> ()) -> (), @ViewBuilder label: @escaping () -> Label) {
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
    
    init(isLoading: Bool, action: @escaping () -> (), @ViewBuilder label: @escaping () -> Label) {
        self.externalIsLoading = isLoading
        self.label = label
        self.action = {
            action()
        }
    }
    
    var body: some View {
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
            ZStack {
                label()
                    .opacity(isLoading ? 0.5 : 1)
                Group {
                    if #available(iOS 15.0, *) {
                        ProgressView()
                            .tint(.white)
                    } else {
                        ProgressView()
                            .accentColor(.white)
                    }
                }
                .opacity(isLoading ? 1 : 0)
            }
            .animation(.default, value: isLoading)
        }
        .disabled(isLoading)
    }
}
