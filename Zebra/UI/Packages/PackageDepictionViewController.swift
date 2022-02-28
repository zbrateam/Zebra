//
//  PackageDepictionViewController.swift
//  Zebra
//
//  Created by Amy While on 28/12/2021.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

import WebKit
import UIKit
import DepictionKit
import Evander

@objc(ZBPackageDepictionViewController)
class PackageDepictionViewController: UIViewController {
    
    private let package: PLPackage
    private var depictionDisplay: DepictionDisplay

	private var webViewContentSizeObserver: NSKeyValueObservation?
    
    private enum DepictionDisplay {
        // Internet is not available or the package has no depictions set
        case offline
        // No Native Depiction is available
        case web
        // A native depiction to be rendered using DepictionKit
        case native
    }
    
    private func configureTheme() -> Theme {
        Theme(text_color: .label,
              background_color: .clear,
							tint_color: .accent ?? .systemBlue,
              separator_color: .separator,
              dark_mode: traitCollection.userInterfaceStyle == .dark)
    }
    
    private lazy var parentStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .fill
        view.distribution = .fill
        view.axis = .vertical
        view.addArrangedSubview(webDepictionView)
        view.addSubview(offlineDepictionView)
        view.addArrangedSubview(expandingView)
        return view
    }()
    
    private let expandingView: UIView = { // DO NOT DELETE
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        view.isHidden = true
        return view
    }()
    
    private let webDepictionActivityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.startAnimating()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingDepictionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.text = "Loading Depiction…"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var loadingDepictionStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .fill
        view.distribution = .fill
        view.axis = .vertical
        view.spacing = 8
        view.addArrangedSubview(webDepictionActivityIndicator)
        view.addArrangedSubview(loadingDepictionLabel)
        return view
    }()
    
    private lazy var webViewHeightAnchor = webView.heightAnchor.constraint(equalToConstant: 100)
    private var webView: WKWebView = {
        let view = WKWebView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.scrollView.isScrollEnabled = false
        return view
    }()

    private lazy var nativeDepictionView: DepictionContainer = {
        let view = DepictionContainer(presentationController: self, theme: self.configureTheme(), delegate: self)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private lazy var webDepictionView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.addArrangedSubview(loadingDepictionStackView)
        view.addArrangedSubview(webView)
        view.addArrangedSubview(nativeDepictionView)
        
        let dummyView = UIView()
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        dummyView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        view.addArrangedSubview(dummyView)
         
        view.isHidden = true
        return view
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private lazy var offlineDepictionStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .fill
        view.distribution = .fill
        view.axis = .vertical
        view.addArrangedSubview(descriptionLabel)
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.33).isActive = true
        separator.backgroundColor = .opaqueSeparator
        view.addArrangedSubview(separator)
        
        view.isHidden = true
        return view
    }()
    
    private lazy var offlineDepictionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(offlineDepictionStackView)
        NSLayoutConstraint.activate([
            offlineDepictionStackView.topAnchor.constraint(equalTo: view.topAnchor),
            offlineDepictionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineDepictionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineDepictionStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return view
    }()
    
    @objc public init(package: PLPackage) {
        self.package = package
        depictionDisplay = .web
        /*
        if package.nativeDepictionURL() != nil {
            depictionDisplay = .native
        } else if package.depictionURL() != nil {
            depictionDisplay = .web
        } else {
            depictionDisplay = .offline
        }
        */
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        view.addSubview(parentStackView)
        NSLayoutConstraint.activate([
            parentStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            parentStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            parentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            parentStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            webViewHeightAnchor
        ])
        
        setDepiction()
    }
    
    private func setDepiction() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.setDepiction()
            }
            return
        }
			
			webViewContentSizeObserver = nil
        switch depictionDisplay {
        case .offline:
            offlineDepictionView.isHidden = false
            descriptionLabel.text = package.longDescription
            NSLog("[Zebra] Long Description = \(package.longDescription) Height = \(descriptionLabel.bounds)")
        case .web:
            webDepictionView.isHidden = false
            guard let url = package.depictionURL else {
                depictionDisplay = .offline
                return setDepiction()
            }
            let request = NSMutableURLRequest(url: url)
            request.allHTTPHeaderFields = URLController.webHeaders
            webView._applicationNameForUserAgent = URLController.webUserAgent
					webViewContentSizeObserver = webView.scrollView.observe(\.contentSize) { _, change in
						if self.webViewHeightAnchor.constant != self.webView.scrollView.contentSize.height {
							self.webViewHeightAnchor.constant = self.webView.scrollView.contentSize.height
							self.view.layoutIfNeeded()
						}
					}
            webView.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
            webView.load(request as URLRequest)
        case .native:
            webDepictionView.isHidden = false
            let url = URL(string: "https://elihwyma.github.io/Aemulo/NativeDepiction.json")!
            /*
            guard let url = package.nativeDepictionURL() else {
                depictionDisplay = .offline
                return setDepiction()
            }
             */
            nativeDepictionView.isHidden = false
            EvanderNetworking.request(url: url, type: [String: Any].self) { [weak self] _, _, _, dict in
                guard let self = self else { return }
                guard let dict = dict else {
                    self.depictionDisplay = .offline
                    return self.setDepiction()
                }
                Thread.mainBlock {
                    self.loadingDepictionStackView.isHidden = true
                    self.nativeDepictionView.setDepiction(dict: dict)
                }
                
            }
        }
    }
}

extension PackageDepictionViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.isHidden = false
        loadingDepictionStackView.isHidden = true
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        let type = navigationAction.navigationType
        if url == self.webView.url || type == .other {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            guard let url = url else { return }
            if url.absoluteString != "about:blank" && url.scheme == "https" || url.scheme == "http" {
							URLController.open(url: url, sender: self)
            }
        }
    }
}

extension PackageDepictionViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        nil
    }
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}

extension PackageDepictionViewController: DepictionDelegate {
    
    public func handleAction(action: DepictionAction) {
        
    }
    
    public func depictionError(error: String) {
        
    }
    
    public func packageView(for package: DepictionPackage) -> UIView {
        UIView()
    }
    
}
